# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/conformal_risk_control.R")

out <- "outputs/crc"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
result <- run_crc_experiment()
for (name in names(result)) write.csv(result[[name]], file.path(out, paste0("single_", name, ".csv")), row.names = FALSE)
write.csv(data.frame(n_train = 1000, n_cal = 400, n_test = 2000, alpha = 0.1,
                     seed = 20261025, grid_points = 201), file.path(out, "single_configuration.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(out, "single_session-info.txt"))
print(result$metrics, row.names = FALSE)
message("CRC outputs written to outputs/crc/.")
