# Fixed, outcome-independent partition; no threshold learning on calibration data.
mondrian_group <- function(data) {
  stopifnot(all(data$treatment %in% c(0, 1)), all(is.finite(data$biomarker)))
  paste0(ifelse(data$treatment == 0, "Control", "Investigational"),
         ifelse(data$biomarker <= 0, "_nonpositive", "_positive"))
}
mondrian_levels <- function() {
  c("Control_nonpositive", "Control_positive",
    "Investigational_nonpositive", "Investigational_positive")
}
calibrate_mondrian <- function(model, calibration, alpha = 0.10) {
  groups <- mondrian_group(calibration)
  residuals <- if (nrow(calibration)) {
    abs(calibration$improvement_week12 - as.numeric(predict(model, calibration)))
  } else numeric(0)
  do.call(rbind, lapply(mondrian_levels(), function(g) {
    scores <- residuals[groups == g]
    n <- length(scores)
    k <- ceiling((n + 1) * (1 - alpha))
    data.frame(group = g, n_cal = n, rank = k, alpha = alpha,
               radius = conformal_radius(scores, alpha),
               uninformative = k > n,
               continuous_score_rank_coverage = if (k > n) 1 else k / (n + 1))
  }))
}
predict_mondrian <- function(model, calibration_table, newdata) {
  stopifnot(!anyDuplicated(calibration_table$group),
            setequal(calibration_table$group, mondrian_levels()))
  groups <- mondrian_group(newdata)
  radius <- calibration_table$radius[match(groups, calibration_table$group)]
  stopifnot(all(radius >= 0))
  center <- as.numeric(predict(model, newdata))
  data.frame(id = newdata$id, treatment = newdata$treatment,
             method = "Mondrian arm x biomarker", center = center,
             lower = center - radius, upper = center + radius)
}
evaluate_mondrian_comparison <- function(intervals, test) {
  result <- evaluate_intervals(intervals, test)
  index <- match(intervals$id, test$id)
  groups <- mondrian_group(test)[index]
  outcome <- test$improvement_week12[index]
  cells <- do.call(rbind, lapply(unique(intervals$method), function(method) {
    do.call(rbind, lapply(mondrian_levels(), function(g) {
      keep <- intervals$method == method & groups == g
      n <- sum(keep)
      widths <- intervals$upper[keep] - intervals$lower[keep]
      covered <- outcome[keep] >= intervals$lower[keep] & outcome[keep] <= intervals$upper[keep]
      data.frame(method = method, group = g, n_test = n,
                 coverage = if (n) mean(covered) else NA_real_,
                 mean_width = if (n) mean(widths) else NA_real_,
                 uninformative_fraction = if (n) mean(!is.finite(widths)) else NA_real_)
    }))
  }))
  rbind(result, cells)
}
run_mondrian_experiment <- function(config = prediction_config(), scenario = "linear", seed = config$seed) {
  train <- simulate_prediction_cohort(config$n_train, seed, "train", scenario, config$effect)
  cal <- simulate_prediction_cohort(config$n_cal, seed + 1L, "cal", scenario, config$effect)
  test <- simulate_prediction_cohort(config$n_test, seed + 2L, "test", scenario, config$effect)
  assert_disjoint_cohorts(train, cal, test)
  model <- fit_outcome_model(train)
  arm <- calibrate_by_arm(model, cal, config$alpha)
  cells <- calibrate_mondrian(model, cal, config$alpha)
  x <- test[c("id", "treatment", "baseline_score", "age", "biomarker")]
  intervals <- rbind(predict_model_based(model, x, config$alpha),
                     predict_conformal(model, arm, x), predict_mondrian(model, cells, x))
  metrics <- evaluate_mondrian_comparison(intervals, test)
  metrics$scenario <- scenario
  metrics$nominal_coverage <- 1 - config$alpha
  intervals$observed <- test$improvement_week12[match(intervals$id, test$id)]
  intervals$group <- mondrian_group(test)[match(intervals$id, test$id)]
  list(metrics = metrics, intervals = intervals, calibration = cells)
}
# Empty test groups are explicitly excluded and their count is reported.
# Infinite widths remain infinite; never omit them to make width appear favorable.
summarize_mondrian <- function(results) {
  key <- interaction(results$n_cal_total, results$scenario, results$method, results$group, drop = TRUE)
  out <- lapply(split(results, key), function(d) {
    valid <- !is.na(d$coverage)
    v <- d[valid, ]
    n <- nrow(v)
    avg <- function(x) if (length(x)) mean(x) else NA_real_
    se <- function(x) if (length(x) > 1 && all(is.finite(x))) sd(x) / sqrt(length(x)) else NA_real_
    cov <- avg(v$coverage); err <- se(v$coverage)
    data.frame(n_cal_total = d$n_cal_total[1], scenario = d$scenario[1],
               method = d$method[1], group = d$group[1], replicates = nrow(d),
               evaluated_replicates = n, empty_test_replicates = sum(!valid),
               nominal_coverage = d$nominal_coverage[1], mean_coverage = cov,
               coverage_mcse = err,
               coverage_mc_lower = if (n > 1) max(0, cov - qt(.975, n - 1) * err) else NA_real_,
               coverage_mc_upper = if (n > 1) min(1, cov + qt(.975, n - 1) * err) else NA_real_,
               mean_width = avg(v$mean_width), width_mcse = se(v$mean_width),
               mean_uninformative_fraction = avg(v$uninformative_fraction),
               fraction_replicates_with_infinite_width = avg(as.numeric(is.infinite(v$mean_width))))
  })
  result <- do.call(rbind, out); rownames(result) <- NULL
  result
}
