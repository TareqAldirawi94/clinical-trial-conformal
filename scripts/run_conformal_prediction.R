# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/conformal_prediction.R")
source("R/prediction_experiment.R")

cfg <- prediction_config()
out <- file.path("outputs", "conformal")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
runs <- lapply(seq_along(cfg$scenarios), function(j) {
  result <- run_prediction_experiment(cfg, cfg$scenarios[j], cfg$seed + 10000L * j)
  result$calibration$scenario <- cfg$scenarios[j]
  result
})
metrics <- do.call(rbind, lapply(runs, function(x) x$metrics))
intervals <- do.call(rbind, lapply(runs, function(x) x$intervals))
calibration_table <- do.call(rbind, lapply(runs, function(x) x$calibration))
write.csv(metrics, file.path(out, "single_run_metrics.csv"), row.names = FALSE)
write.csv(intervals, file.path(out, "prediction_intervals.csv"), row.names = FALSE)
write.csv(calibration_table, file.path(out, "calibration_details.csv"), row.names = FALSE)
write.csv(as.data.frame(cfg[setdiff(names(cfg), "scenarios")]),
          file.path(out, "configuration.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(out, "session-info.txt"))
# Plot the first 30 test patients; the selection never depends on their outcomes.
png(file.path(out, "individual_prediction_intervals.png"), width = 1400, height = 1000, res = 130)
par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
for (scenario in cfg$scenarios) {
  for (method in c("Model-based", "Split conformal")) {
    panel <- head(intervals[intervals$scenario == scenario & intervals$method == method, ], 30)
    finite_values <- c(panel$lower, panel$upper, panel$observed)
    finite_values <- finite_values[is.finite(finite_values)]
    x <- seq_len(nrow(panel))
    plot(x, panel$observed, ylim = range(finite_values), pch = 19,
         xlab = "Test patient (first 30)", ylab = "Week-12 improvement",
         main = paste(scenario, method, sep = " / "), cex.main = 0.8)
    covered <- panel$observed >= panel$lower & panel$observed <= panel$upper
    segments(x, panel$lower, x, panel$upper, col = ifelse(covered, "#398A80", "#C14D44"))
    points(x, panel$observed, pch = 19, cex = 0.6)
  }
}
dev.off()
print(metrics[metrics$group %in% c("Overall", "Control", "Investigational"), ], row.names = FALSE)
message("Conformal comparison saved to outputs/conformal/. Run the repeated experiment before drawing conclusions.")
