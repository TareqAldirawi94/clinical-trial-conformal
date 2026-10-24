# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/config.R")
source("R/simulate_trial.R")
source("R/analyze_trial.R")
cfg <- trial_config()
args <- commandArgs(trailingOnly = TRUE)
reps <- if (length(args)) suppressWarnings(as.numeric(args[1])) else 1000
stopifnot(length(reps) == 1, is.finite(reps), reps >= 2, reps == floor(reps))
rows <- lapply(seq_along(c(0, cfg$effect)), function(scenario) {
  truth <- c(0, cfg$effect)[scenario]
  results <- do.call(rbind, lapply(seq_len(reps), function(i) {
    data <- simulate_trial(cfg$n, truth, cfg$residual_sd,
                           cfg$seed + scenario * 100000L + i)
    analyze_trial(data, cfg$test_alpha)
  }))
  rejection <- mean(results$reject)
  covered <- results$lower <= truth & results$upper >= truth
  coverage <- mean(covered)
  binomial_ci <- binom.test(sum(results$reject), reps)$conf.int
  data.frame(scenario = if (truth == 0) "Null" else "Alternative",
             true_effect = truth, replicates = reps,
             rejection_rate = rejection,
             rejection_mcse = sqrt(rejection * (1 - rejection) / reps),
             rejection_mc_lower = binomial_ci[1], rejection_mc_upper = binomial_ci[2],
             bias = mean(results$estimate - truth),
             bias_mcse = sd(results$estimate) / sqrt(reps),
             rmse = sqrt(mean((results$estimate - truth)^2)),
             ci_coverage = coverage,
             coverage_mcse = sqrt(coverage * (1 - coverage) / reps))
})
summary <- do.call(rbind, rows)
dir.create("outputs", showWarnings = FALSE)
write.csv(summary, "outputs/operating_characteristics.csv", row.names = FALSE)
print(summary)
