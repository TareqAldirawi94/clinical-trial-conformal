# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/conformal_prediction.R")
source("R/prediction_experiment.R")

# Exact ranks, ties, empty arms, invalid scores, and small-sample infinity.
stopifnot(conformal_radius(1:9, 0.10) == 9,
          conformal_radius(1:19, 0.10) == 18,
          is.infinite(conformal_radius(1:8, 0.10)),
          is.infinite(conformal_radius(numeric(0), 0.10)),
          conformal_radius(rep(2, 19), 0.10) == 2,
          inherits(try(conformal_radius(c(1, NA)), silent = TRUE), "try-error"),
          inherits(try(conformal_radius(c(-1, 2)), silent = TRUE), "try-error"))
train <- simulate_prediction_cohort(100, 101, "train")
cal <- simulate_prediction_cohort(40, 102, "cal")
test <- simulate_prediction_cohort(60, 103, "test")
assert_disjoint_cohorts(train, cal, test)
stopifnot(inherits(try(assert_disjoint_cohorts(train, train, test), silent = TRUE), "try-error"))
model <- fit_outcome_model(train)
tab <- calibrate_by_arm(model, cal)
pred <- predict_conformal(model, tab, test)
stopifnot(all(tab$n_cal == 20), all(tab$rank == 19), nrow(pred) == nrow(test))
# Independently compute arm 0's threshold from its residual order statistic.
residuals0 <- abs(cal$improvement_week12[cal$treatment == 0] -
                 predict(model, cal[cal$treatment == 0, ]))
stopifnot(abs(tab$radius[tab$treatment == 0] - sort(residuals0)[19]) < 1e-10)
# Calibration changes in arm 0 must not affect arm 1.
changed <- cal
changed$improvement_week12[changed$treatment == 0] <- changed$improvement_week12[changed$treatment == 0] + 100
changed_tab <- calibrate_by_arm(model, changed)
stopifnot(identical(tab$radius[2], changed_tab$radius[2]), changed_tab$radius[1] > tab$radius[1])
# Missing arm: its radius must be infinite.
empty_arm <- calibrate_by_arm(model, cal[cal$treatment == 0, ])
stopifnot(empty_arm$n_cal[2] == 0, is.infinite(empty_arm$radius[2]))
empty_all <- calibrate_by_arm(model, cal[FALSE, ])
stopifnot(all(is.infinite(empty_all$radius)))
# Test labels cannot affect either method's predictions.
changed_test <- test
changed_test$improvement_week12 <- changed_test$improvement_week12 + 1000
stopifnot(identical(pred, predict_conformal(model, tab, changed_test)),
          identical(predict_model_based(model, test), predict_model_based(model, changed_test)))
# Evaluation matches patients by ID, not their row positions.
metrics <- evaluate_intervals(pred, test)
stopifnot(identical(metrics, evaluate_intervals(pred, test[nrow(test):1, ])))
# Prediction uncertainty includes new-outcome variance, beyond mean uncertainty.
pi <- predict_model_based(model, test)
mean_ci <- predict(model, test, interval = "confidence", level = 0.9)
stopifnot(all(pi$upper - pi$lower > mean_ci[, "upr"] - mean_ci[, "lwr"]))
# A common translation of all outcomes shifts interval endpoints, preserving widths.
shifted_train <- train; shifted_cal <- cal
shifted_train$improvement_week12 <- train$improvement_week12 + 7
shifted_cal$improvement_week12 <- cal$improvement_week12 + 7
shifted_model <- fit_outcome_model(shifted_train)
shifted_pred <- predict_conformal(shifted_model, calibrate_by_arm(shifted_model, shifted_cal), test)
stopifnot(max(abs(shifted_pred$lower - pred$lower - 7)) < 1e-8,
          max(abs(shifted_pred$upper - pred$upper - 7)) < 1e-8)
# Both scenario pipelines and the replicate summarizer execute on small cohorts.
cfg <- prediction_config(); cfg$n_train <- 100; cfg$n_cal <- 40; cfg$n_test <- 60
for (scenario in cfg$scenarios) {
  r1 <- run_prediction_experiment(cfg, scenario, 201)$metrics
  r2 <- run_prediction_experiment(cfg, scenario, 204)$metrics
  summary_result <- summarize_prediction_replicates(rbind(r1, r2))
  stopifnot(nrow(summary_result) == 10, all(summary_result$replicates == 2),
            all(is.finite(summary_result$mean_width)),
            all(summary_result$mean_coverage >= 0 & summary_result$mean_coverage <= 1))
}
cat("All conformal prediction tests passed.\n")
