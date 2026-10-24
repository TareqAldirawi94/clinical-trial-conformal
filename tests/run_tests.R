# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/analyze_trial.R")
data <- simulate_trial(seed = 101)
stopifnot(identical(data, simulate_trial(seed = 101)),
          sum(data$treatment == 1) == 120,
          sum(data$treatment == 0) == 120,
          !anyNA(data), !anyDuplicated(data$id))
events <- as.matrix(data[grep("^ae_", names(data))])
stopifnot(all(events %in% c(0, 1)))

# Known additive shift must move the adjusted effect and CI by exactly 5.
shifted <- data
shifted$improvement_week12 <- shifted$improvement_week12 + 5 * shifted$treatment
a <- analyze_trial(data)
b <- analyze_trial(shifted)
stopifnot(abs(b$estimate - a$estimate - 5) < 1e-8,
          abs(b$lower - a$lower - 5) < 1e-8,
          abs(b$standard_error - a$standard_error) < 1e-8)
missing <- data
missing$improvement_week12[1] <- NA
stopifnot(inherits(try(analyze_trial(missing), silent = TRUE), "try-error"),
          inherits(try(simulate_trial(n = 21), silent = TRUE), "try-error"))
safe <- safety_table(data)
stopifnot(nrow(safe) == 10, all(safe$denominator == 120),
          all(safe$percent >= 0 & safe$percent <= 100))

# Integration check: both scripts must run and produce the documented files.
source("scripts/run_trial.R")
stopifnot(all(file.exists(file.path("outputs", c("simulated_trial.csv",
          "efficacy_results.csv", "baseline_table.csv", "safety_table.csv",
          "sample_size_planning.csv", "efficacy_plot.png", "session-info.txt")))))
cat("All tests passed.\n")
