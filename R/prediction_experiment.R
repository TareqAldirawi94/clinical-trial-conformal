prediction_config <- function() {
  list(n_train = 1000L, n_cal = 400L, n_test = 2000L,
       alpha = 0.10, effect = 3, seed = 20261024L,
       scenarios = c("linear", "nonlinear_heteroscedastic"))
}

simulate_prediction_cohort <- function(n, seed, prefix, scenario = "linear", effect = 3) {
  scenario <- match.arg(scenario, c("linear", "nonlinear_heteroscedastic"))
  data <- simulate_trial(n = n, effect = effect, residual_sd = 8, seed = seed)
  if (scenario == "nonlinear_heteroscedastic") {
    mean_linear <- 4 + effect * data$treatment + 0.25 * (data$baseline_score - 50) +
      0.8 * data$biomarker - 0.03 * (data$age - 55)
    standardized_noise <- (data$improvement_week12 - mean_linear) / 8
    # The fitted model omits this nonlinear term and the varying noise scale.
    true_mean <- mean_linear + 4 * (data$biomarker^2 - 1)
    true_sd <- ifelse(data$biomarker > 0, 12, 4)
    data$improvement_week12 <- true_mean + true_sd * standardized_noise
  }
  data$id <- paste(prefix, data$id, sep = "_")
  data
}

run_prediction_experiment <- function(config = prediction_config(), scenario = "linear",
                                      seed = config$seed) {
  training <- simulate_prediction_cohort(config$n_train, seed, "train", scenario, config$effect)
  calibration <- simulate_prediction_cohort(config$n_cal, seed + 1L, "cal", scenario, config$effect)
  test <- simulate_prediction_cohort(config$n_test, seed + 2L, "test", scenario, config$effect)
  assert_disjoint_cohorts(training, calibration, test)
  model <- fit_outcome_model(training)
  calibration_table <- calibrate_by_arm(model, calibration, config$alpha)
  # Only predictors and identifiers are passed to the prediction routines.
  predictors <- test[c("id", "treatment", "baseline_score", "age", "biomarker")]
  intervals <- rbind(predict_model_based(model, predictors, config$alpha),
                     predict_conformal(model, calibration_table, predictors))
  metrics <- evaluate_intervals(intervals, test)
  metrics$scenario <- scenario
  metrics$nominal_coverage <- 1 - config$alpha
  # Outcome attached only after predictions are fixed, for inspection and plots.
  intervals$observed <- test$improvement_week12[match(intervals$id, test$id)]
  intervals$scenario <- scenario
  list(metrics = metrics, intervals = intervals, calibration = calibration_table)
}

summarize_prediction_replicates <- function(results) {
  keys <- interaction(results$scenario, results$method, results$group, drop = TRUE)
  summaries <- lapply(split(results, keys), function(d) {
    r <- nrow(d)
    mcse <- sd(d$coverage) / sqrt(r)
    data.frame(scenario = d$scenario[1], method = d$method[1], group = d$group[1],
               replicates = r, nominal_coverage = d$nominal_coverage[1],
               mean_coverage = mean(d$coverage), coverage_mcse = mcse,
               coverage_mc_lower = max(0, mean(d$coverage) - qt(0.975, r - 1) * mcse),
               coverage_mc_upper = min(1, mean(d$coverage) + qt(0.975, r - 1) * mcse),
               mean_width = mean(d$mean_width),
               width_mcse = if (all(is.finite(d$mean_width))) sd(d$mean_width) / sqrt(r) else NA_real_,
               mean_uninformative_fraction = mean(d$uninformative_fraction))
  })
  result <- do.call(rbind, summaries)
  rownames(result) <- NULL
  result
}
