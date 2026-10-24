# Synthetic educational data only. Units are arbitrary clinical-score points.
simulate_trial <- function(n = 240L, effect = 3, residual_sd = 8,
                           seed = 20261023L) {
  stopifnot(length(n) == 1L, is.finite(n), n >= 20, n %% 2 == 0,
            length(effect) == 1L, is.finite(effect),
            length(residual_sd) == 1L, is.finite(residual_sd), residual_sd > 0)
  set.seed(seed)
  age <- pmin(80, pmax(18, rnorm(n, 55, 12)))
  baseline_score <- rnorm(n, 50, 10)
  biomarker <- rnorm(n)
  treatment <- sample(rep(c(0L, 1L), each = n / 2))
  # Constant additive efficacy effect, correctly specified Gaussian ANCOVA.
  improvement <- 4 + effect * treatment + 0.25 * (baseline_score - 50) +
    0.8 * biomarker - 0.03 * (age - 55) + rnorm(n, 0, residual_sd)
  # Shared latent susceptibility produces correlated adverse-event outcomes.
  susceptibility <- rnorm(n)
  ae_names <- c("nausea", "fatigue", "rash", "diarrhea", "headache")
  intercepts <- c(-1.8, -1.2, -2.4, -2.0, -1.6)
  aes <- sapply(seq_along(ae_names), function(j) {
    p <- plogis(intercepts[j] + 0.35 * treatment +
                  0.15 * biomarker + 0.6 * susceptibility)
    rbinom(n, 1, p)
  })
  colnames(aes) <- paste0("ae_", ae_names)
  data.frame(id = sprintf("SIM%04d", seq_len(n)), treatment = treatment,
             age = age, baseline_score = baseline_score, biomarker = biomarker,
             improvement_week12 = improvement, aes, check.names = FALSE)
}
