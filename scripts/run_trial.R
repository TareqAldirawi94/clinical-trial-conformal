# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/config.R")
source("R/simulate_trial.R")
source("R/analyze_trial.R")
cfg <- trial_config()
dir.create("outputs", showWarnings = FALSE)
data <- simulate_trial(cfg$n, cfg$effect, cfg$residual_sd, cfg$seed)
result <- analyze_trial(data, cfg$test_alpha)
write.csv(data, "outputs/simulated_trial.csv", row.names = FALSE)
write.csv(result, "outputs/efficacy_results.csv", row.names = FALSE)
write.csv(baseline_table(data), "outputs/baseline_table.csv", row.names = FALSE)
write.csv(safety_table(data), "outputs/safety_table.csv", row.names = FALSE)

# Conservative normal approximation: ignores precision gain from covariates.
# This is an illustrative planning calculation, not a clinical recommendation.
outcome_sd <- sqrt(cfg$residual_sd^2 + 0.25^2 * 10^2 + 0.8^2 + 0.03^2 * 12^2)
per_arm <- ceiling(2 * (qnorm(1 - cfg$test_alpha / 2) +
                         qnorm(cfg$target_power))^2 * outcome_sd^2 / cfg$effect^2)
write.csv(data.frame(effect = cfg$effect, planning_sd = outcome_sd,
                     alpha = cfg$test_alpha, power = cfg$target_power,
                     approximate_n_per_arm = per_arm, planned_total_n = cfg$n),
          "outputs/sample_size_planning.csv", row.names = FALSE)
png("outputs/efficacy_plot.png", width = 1000, height = 700, res = 130)
boxplot(improvement_week12 ~ factor(treatment, levels = 0:1,
                                   labels = c("Control", "Investigational")),
        data = data, col = c("#A9C4D6", "#69B5A2"),
        ylab = "Week-12 improvement (arbitrary points; higher is better)",
        xlab = "Randomized arm", main = "Simulated Phase II trial")
dev.off()
capture.output(sessionInfo(), file = "outputs/session-info.txt")
print(result)
message("Trial outputs written to outputs/.")
