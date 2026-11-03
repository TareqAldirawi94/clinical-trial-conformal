setwd("C:/Users/telde/Downloads/clinical-trial-conformal-starter/clinical-trial-conformal")

# Check the new implementation
source("tests/test_mondrian.R")

# Inspect one simulated experiment
source("scripts/run_mondrian_prediction.R")

# Compare methods across calibration sample sizes
options(
  mondrian.replicates = 200,
  mondrian.calibration_sizes = c(40, 100, 400)
)
source("scripts/run_mondrian_repeated.R")


setwd("C:/Users/telde/Downloads/clinical-trial-conformal-starter/clinical-trial-conformal")

source("tests/test_crc.R")
source("scripts/run_crc.R")

options(
  crc.replicates = 200,
  crc.calibration_sizes = c(40, 100, 400)
)
source("scripts/run_crc_repeated.R")