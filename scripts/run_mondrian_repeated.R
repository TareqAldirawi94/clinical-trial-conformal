# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/conformal_prediction.R")
source("R/prediction_experiment.R")
source("R/mondrian_prediction.R")

args <- commandArgs(trailingOnly = TRUE)
reps <- if (length(args)) suppressWarnings(as.numeric(args[1])) else getOption("mondrian.replicates", 200L)
sizes <- getOption("mondrian.calibration_sizes", c(40L, 100L, 400L))
stopifnot(length(reps) == 1, is.finite(reps), reps >= 2, reps == floor(reps),
          length(sizes) > 0, all(is.finite(sizes)), all(sizes >= 20), all(sizes %% 2 == 0), !anyDuplicated(sizes))
cfg <- prediction_config()
out <- "outputs/mondrian"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
metrics <- list(); calibration <- list(); position <- 0L
for (ncal in sizes) {
  cfg$n_cal <- ncal
  for (j in seq_along(cfg$scenarios)) {
    for (i in seq_len(reps)) {
      # Same seed schedule as the previous repeated CP experiment.
      # Within a size/scenario all methods share train/cal/test data.
      result <- run_mondrian_experiment(cfg, cfg$scenarios[j], cfg$seed + j * 1000000 + 3 * i)
      position <- position + 1L
      result$metrics$n_cal_total <- ncal
      result$metrics$replicate <- i
      metrics[[position]] <- result$metrics
      result$calibration$n_cal_total <- ncal
      result$calibration$scenario <- cfg$scenarios[j]
      result$calibration$replicate <- i
      calibration[[position]] <- result$calibration
      if (i %% 25 == 0 || i == reps) message("n_cal=", ncal, ", ", cfg$scenarios[j], ": ", i, "/", reps)
    }
  }
}
metrics <- do.call(rbind, metrics)
calibration <- do.call(rbind, calibration)
summary_results <- summarize_mondrian(metrics)
write.csv(metrics, file.path(out, "replicate_metrics.csv"), row.names = FALSE)
write.csv(summary_results, file.path(out, "repeated_summary.csv"), row.names = FALSE)
write.csv(calibration, file.path(out, "replicate_calibration.csv"), row.names = FALSE)
write.csv(data.frame(n_train = cfg$n_train, n_cal = sizes, n_test = cfg$n_test,
                     alpha = cfg$alpha, effect = cfg$effect, seed = cfg$seed, replicates = reps),
          file.path(out, "repeated_configuration.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(out, "session-info.txt"))
print(summary_results[summary_results$n_cal_total == max(sizes) &
                       summary_results$group %in% c("Overall", mondrian_levels()), ], row.names = FALSE)
message("All calibration sizes saved to outputs/mondrian/repeated_summary.csv")
