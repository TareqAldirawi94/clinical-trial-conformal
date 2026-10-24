# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/conformal_risk_control.R")
y <- rbind(c(1, 1, 0, 0, 0), c(0, 0, 0, 0, 0))
s <- rbind(c(1, 0, 0, 0, 0), c(0, 0, 0, 0, 0))
stopifnot(identical(missed_event_loss(y, s), c(0.5, 0)))
# Analytic example: empirical allows one miss out of ten; CRC allows zero.
y <- matrix(0, 10, 5); y[, 1] <- 1
prob <- matrix(0, 10, 5); prob[, 1] <- c(0.1, rep(0.9, 9))
e <- select_ae_threshold(prob, y, method = "Empirical", grid = c(0, 0.2, 0.95, 1))
c <- select_ae_threshold(prob, y, method = "CRC", grid = c(0, 0.2, 0.95, 1))
stopifnot(e$lambda == 0.2, c$lambda == 0.95, c$corrected_risk <= 0.1)
# n=8 cannot satisfy the corrected criterion at alpha=.1, even with zero loss.
z <- select_ae_threshold(prob[1:8, ], y[1:8, ])
stopifnot(z$lambda == 1, z$safe_all_labels_fallback)
z <- select_ae_threshold(prob[FALSE, ], y[FALSE, ])
stopifnot(z$lambda == 1, z$safe_all_labels_fallback)
losses <- vapply(seq(0, 1, length.out = 21), function(l)
  mean(missed_event_loss(y, prob >= 1-l)), numeric(1))
stopifnot(all(diff(losses) <= 0), tail(losses, 1) == 0)
# Arm isolation and exact mapping of thresholds to patient rows.
prob <- rbind(prob, prob); y <- rbind(y, y); arm <- rep(0:1, each = 10)
tab <- calibrate_ae_by_arm(prob, y, arm)
y2 <- y; y2[arm == 1, ] <- 0
tab2 <- calibrate_ae_by_arm(prob, y2, arm)
stopifnot(identical(tab[tab$treatment == 0, ], tab2[tab2$treatment == 0, ]))
sets <- predict_ae_sets(prob, arm, tab, "CRC")
ord <- rev(seq_len(nrow(prob)))
stopifnot(identical(sets[ord, ], predict_ae_sets(prob[ord, ], arm[ord], tab, "CRC")))
for (a in 0:1) {
  lambda <- tab$lambda[tab$method == "CRC" & tab$treatment == a]
  stopifnot(all(sets[arm == a, ] == (prob[arm == a, ] >= 1-lambda)))
}
# Held-out outcomes cannot affect scores; absent classes use training-only fallback.
train <- simulate_trial(100, seed = 71)
train[, ae_columns] <- 0
models <- fit_ae_models(train)
stopifnot(all(vapply(models, function(m) m$fallback, logical(1))))
test <- simulate_trial(40, seed = 72)
p1 <- predict_ae(models, test)
test[, ae_columns] <- 1
stopifnot(identical(p1, predict_ae(models, test)))
# End-to-end reproducibility and shared test cohort for all methods.
a <- run_crc_experiment(100, 40, 40, seed = 91)
b <- run_crc_experiment(100, 40, 40, seed = 91)
stopifnot(identical(a, b), nrow(a$metrics) == 15,
          nrow(a$calibration) == 6, nrow(a$predictions) == 120,
          all(a$metrics$risk >= 0 & a$metrics$risk <= 1),
          all(a$metrics$mean_set_size >= 0 & a$metrics$mean_set_size <= 5))
for (arm_value in 0:1) {
  rows <- a$calibration[a$calibration$treatment == arm_value, ]
  stopifnot(rows$lambda[rows$method == "CRC"] >= rows$lambda[rows$method == "Empirical"])
}
m <- a$metrics; m$n_cal_total <- 40; m$replicate <- 1
m2 <- b$metrics; m2$n_cal_total <- 40; m2$replicate <- 2
summary_results <- summarize_crc(rbind(m, m2))
stopifnot(nrow(summary_results) == 15, all(summary_results$risk_mcse == 0))
message("All CRC tests passed.")
