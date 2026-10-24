# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/conformal_prediction.R")
source("R/prediction_experiment.R")

# RStudio: options(conformal.replicates = 200); source this script.
# Terminal: Rscript scripts/run_conformal_repeated.R 200
args <- commandArgs(trailingOnly = TRUE)
reps <- if (length(args)) suppressWarnings(as.numeric(args[1])) else getOption("conformal.replicates", 200L)
stopifnot(length(reps) == 1, is.finite(reps), reps >= 2, reps == floor(reps))
cfg <- prediction_config()
out <- file.path("outputs", "conformal")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
results <- vector("list", length(cfg$scenarios) * reps)
position <- 0L
for (j in seq_along(cfg$scenarios)) {
  for (i in seq_len(reps)) {
    # Disjoint seed ranges for the two scenarios, three seeds per replicate.
    seed <- cfg$seed + j * 1000000 + 3 * i
    experiment <- run_prediction_experiment(cfg, cfg$scenarios[j], seed)
    position <- position + 1L
    row <- experiment$metrics
    row$replicate <- i
    results[[position]] <- row
    if (i %% 25 == 0 || i == reps) message(cfg$scenarios[j], ": ", i, "/", reps)
  }
}
results <- do.call(rbind, results)
summary_results <- summarize_prediction_replicates(results)
write.csv(results, file.path(out, "replicate_metrics.csv"), row.names = FALSE)
write.csv(summary_results, file.path(out, "repeated_summary.csv"), row.names = FALSE)
write.csv(as.data.frame(cfg[setdiff(names(cfg), "scenarios")]),
          file.path(out, "repeated_configuration.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(out, "repeated-session-info.txt"))
print(summary_results[summary_results$group %in% c("Overall", "Control", "Investigational"), ], row.names = FALSE)
message("Repeated results saved to outputs/conformal/repeated_summary.csv")
