# Run from the repository root (open the .Rproj file in RStudio).
if (!file.exists("R/config.R")) {
  stop("Open clinical-trial-conformal.Rproj or setwd() to the repository root first.")
}

source("R/simulate_trial.R")
source("R/conformal_prediction.R")
source("R/prediction_experiment.R")
source("R/mondrian_prediction.R")

train <- simulate_prediction_cohort(100, 101, "train")
cal <- simulate_prediction_cohort(40, 102, "cal")
test <- simulate_prediction_cohort(60, 103, "test")
model <- fit_outcome_model(train)
# Force exactly ten calibration patients in each of the four cells.
for (a in 0:1) cal$biomarker[cal$treatment == a] <- rep(c(-1, 1), each = 10)
tab <- calibrate_mondrian(model, cal)
stopifnot(all(tab$n_cal == 10), all(tab$rank == 10), all(is.finite(tab$radius)))
scores <- abs(cal$improvement_week12 - predict(model, cal))
for (g in mondrian_levels()) stopifnot(abs(tab$radius[tab$group == g] - max(scores[mondrian_group(cal) == g])) < 1e-10)
# Zero belongs to the nonpositive group, for both arms.
stopifnot(identical(mondrian_group(data.frame(treatment = 0:1, biomarker = c(0, 0))),
                    c("Control_nonpositive", "Investigational_nonpositive")))
# All four rows persist with empty calibration; no pooling fallback.
empty <- calibrate_mondrian(model, cal[FALSE, ])
stopifnot(nrow(empty) == 4, all(empty$n_cal == 0), all(is.infinite(empty$radius)))
groups <- mondrian_group(cal)
small <- cal[groups != mondrian_levels()[1] | seq_len(nrow(cal)) %in% which(groups == mondrian_levels()[1])[1:8], ]
small_tab <- calibrate_mondrian(model, small)
stopifnot(small_tab$n_cal[1] == 8, is.infinite(small_tab$radius[1]))
# Changing one cell's outcomes must leave the other radii unchanged.
changed <- cal; changed$improvement_week12[groups == mondrian_levels()[1]] <- changed$improvement_week12[groups == mondrian_levels()[1]] + 1000
newtab <- calibrate_mondrian(model, changed)
stopifnot(identical(tab$radius[-1], newtab$radius[-1]), newtab$radius[1] > tab$radius[1])
pred <- predict_mondrian(model, tab, test)
changed_test <- test; changed_test$improvement_week12 <- rep(9999, nrow(test))
stopifnot(identical(pred, predict_mondrian(model, tab, changed_test)))
stopifnot(identical(pred, predict_mondrian(model, tab[4:1, ], test)))
# Check exact matching of all four radii and invariance to test ordering.
stopifnot(all(abs((pred$upper - pred$lower)/2 - tab$radius[match(mondrian_group(test), tab$group)]) < 1e-10))
stopifnot(identical(evaluate_mondrian_comparison(pred, test), evaluate_mondrian_comparison(pred, test[nrow(test):1, ])))
# Adding Mondrian must leave the original two methods' results unchanged.
cfg0 <- prediction_config()
old <- run_prediction_experiment(cfg0, "linear", 301)$metrics
new <- run_mondrian_experiment(cfg0, "linear", 301)$metrics
new <- new[new$method %in% old$method & new$group %in% old$group, ]
rownames(old) <- NULL; rownames(new) <- NULL
stopifnot(isTRUE(all.equal(old, new)))
# Infinite widths must survive aggregation, and not be silently dropped.
cfg <- prediction_config(); cfg$n_train <- 100; cfg$n_cal <- 40; cfg$n_test <- 60
for (scenario in cfg$scenarios) {
  a <- run_mondrian_experiment(cfg, scenario, 201)$metrics
  b <- run_mondrian_experiment(cfg, scenario, 204)$metrics
  d <- rbind(a, b); d$n_cal_total <- cfg$n_cal
  summary <- summarize_mondrian(d)
  stopifnot(nrow(summary) == 27, all(summary$replicates == 2))
}
d <- d[1:2, ]; d$method <- "check"; d$group <- "check"; d$mean_width <- c(Inf, 10)
s <- summarize_mondrian(d)
stopifnot(is.infinite(s$mean_width), is.na(s$width_mcse), s$fraction_replicates_with_infinite_width == 0.5)
cat("All Mondrian prediction tests passed.\n")
