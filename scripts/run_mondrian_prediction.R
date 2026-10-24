# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/conformal_prediction.R")
source("R/prediction_experiment.R")
source("R/mondrian_prediction.R")

cfg <- prediction_config()
out <- "outputs/mondrian"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
all_metrics <- list(); all_cal <- list(); all_intervals <- list()
for (j in seq_along(cfg$scenarios)) {
  result <- run_mondrian_experiment(cfg, cfg$scenarios[j], cfg$seed + 10000L * j)
  result$metrics$n_cal_total <- cfg$n_cal
  result$calibration$scenario <- cfg$scenarios[j]
  result$intervals$scenario <- cfg$scenarios[j]
  all_metrics[[j]] <- result$metrics
  all_cal[[j]] <- result$calibration
  all_intervals[[j]] <- result$intervals
}
metrics <- do.call(rbind, all_metrics)
write.csv(metrics, file.path(out, "single_run_metrics.csv"), row.names = FALSE)
write.csv(do.call(rbind, all_cal), file.path(out, "calibration_details.csv"), row.names = FALSE)
write.csv(do.call(rbind, all_intervals), file.path(out, "prediction_intervals.csv"), row.names = FALSE)
write.csv(as.data.frame(cfg[setdiff(names(cfg), "scenarios")]), file.path(out, "configuration.csv"), row.names = FALSE)
print(metrics[metrics$group %in% c("Overall", mondrian_levels()), ], row.names = FALSE)
message("Single-run comparison saved to outputs/mondrian/.")
