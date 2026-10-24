# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/conformal_risk_control.R")

args <- commandArgs(trailingOnly = TRUE)
reps <- if (length(args)) as.numeric(args[1]) else getOption("crc.replicates", 200L)
sizes <- getOption("crc.calibration_sizes", c(40L, 100L, 400L))
stopifnot(length(reps) == 1, is.finite(reps), reps >= 2, reps == floor(reps),
          length(sizes) > 0, all(is.finite(sizes)), all(sizes >= 20),
          all(sizes %% 2 == 0), !anyDuplicated(sizes))
out <- "outputs/crc"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
metrics <- list(); calibration <- list(); diagnostics <- list(); pos <- 0L
for (ncal in sizes) for (i in seq_len(reps)) {
  result <- run_crc_experiment(n_cal = ncal, seed = 20261025 + 3 * i)
  pos <- pos + 1L
  for (name in c("metrics", "calibration", "model_diagnostics")) {
    result[[name]]$replicate <- i; result[[name]]$n_cal_total <- ncal
  }
  metrics[[pos]] <- result$metrics
  calibration[[pos]] <- result$calibration
  diagnostics[[pos]] <- result$model_diagnostics
  if (i %% 25 == 0 || i == reps) message("n_cal=", ncal, ": ", i, "/", reps)
}
metrics <- do.call(rbind, metrics)
summary_results <- summarize_crc(metrics)
write.csv(metrics, file.path(out, "replicate_metrics.csv"), row.names = FALSE)
write.csv(do.call(rbind, calibration), file.path(out, "replicate_calibration.csv"), row.names = FALSE)
write.csv(do.call(rbind, diagnostics), file.path(out, "replicate_model_diagnostics.csv"), row.names = FALSE)
write.csv(summary_results, file.path(out, "repeated_summary.csv"), row.names = FALSE)
write.csv(data.frame(n_train = 1000, n_cal = sizes, n_test = 2000, alpha = 0.1,
                     seed = 20261025, grid_points = 201, replicates = reps),
          file.path(out, "repeated_configuration.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(out, "repeated_session-info.txt"))
print(summary_results[summary_results$group == "Overall", c("n_cal_total", "method", "risk", "risk_mcse", "mean_set_size")], row.names = FALSE)
message("Repeated CRC outputs written to outputs/crc/.")
