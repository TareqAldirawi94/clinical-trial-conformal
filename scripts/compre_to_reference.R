if (!file.exists("R/config.R")) stop("Run from the repository root.")
cmp <- function(fresh, ref, by, vals) {
  a <- read.csv(fresh); b <- read.csv(ref)
  m <- merge(a, b, by = by, suffixes = c(".new", ".ref"))
  cat(fresh, ": ", nrow(m), " matched rows\n", sep = "")
  for (v in vals) {
    d <- max(abs(m[[paste0(v, ".new")]] - m[[paste0(v, ".ref")]]), na.rm = TRUE)
    cat(sprintf("  %-20s max abs diff: %.3g\n", v, d))
  }
}
cmp("outputs/crc/repeated_summary.csv", "results/reference/crc_summary.csv",
    c("n_cal_total", "method", "group"), c("risk", "mean_set_size"))
cmp("outputs/mondrian/repeated_summary.csv", "results/reference/mondrian_summary.csv",
    c("n_cal_total", "scenario", "method", "group"), c("mean_coverage", "mean_width"))
cmp("outputs/conformal/repeated_summary.csv", "results/reference/cp_summary.csv",
    c("scenario", "method", "group"), c("mean_coverage", "mean_width"))
