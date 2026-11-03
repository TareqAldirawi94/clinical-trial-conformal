# Full verification run from the repository root.
if (!file.exists("R/config.R")) stop("Run from the repository root.")
t0 <- Sys.time()

# 1. RNG isolation
source("R/simulate_trial.R")
set.seed(1); a <- runif(1)
set.seed(1); invisible(simulate_trial(seed = 5)); b <- runif(1)
stopifnot(identical(a, b))
cat("RNG check: TRUE\n")

# 2. Tests (the first one also runs scripts/run_trial.R)
source("tests/run_tests.R")
source("tests/test_conformal.R")
source("tests/test_mondrian.R")
source("tests/test_crc.R")

# 3. Sample-size file written by run_trial.R
print(read.csv("outputs/sample_size_planning.csv"))

# 4. Efficacy operating characteristics (1,000 replications per scenario)
source("scripts/run_operating_characteristics.R")

# 5. Repeated experiments (slow)
options(conformal.replicates = 200)
source("scripts/run_conformal_repeated.R")

options(mondrian.replicates = 200, mondrian.calibration_sizes = c(40, 100, 400))
source("scripts/run_mondrian_repeated.R")

options(crc.replicates = 200, crc.calibration_sizes = c(40, 100, 400))
source("scripts/run_crc_repeated.R")

# 6. Compare with committed reference results
source("scripts/compare_to_reference.R")

# 7. Infinite-width cells (NaN-safe check)
a <- read.csv("outputs/mondrian/repeated_summary.csv")
b <- read.csv("results/reference/mondrian_summary.csv")
m <- merge(a, b, by = c("n_cal_total", "scenario", "method", "group"),
           suffixes = c(".new", ".ref"))
cat("Inf in new:", sum(is.infinite(m$mean_width.new)),
    " Inf in ref:", sum(is.infinite(m$mean_width.ref)),
    " mismatch:", sum(is.infinite(m$mean_width.new) != is.infinite(m$mean_width.ref)), "\n")

# 8. Environment and timing
cat(R.version.string, "\n")
cat("Total time:", format(round(difftime(Sys.time(), t0, units = "mins"), 1)), "\n")
cat("ALL CHECKS COMPLETED\n")