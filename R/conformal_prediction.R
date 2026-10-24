# Arm-specific split conformal prediction. Functions do not change directories.
conformal_radius <- function(scores, alpha = 0.10) {
  stopifnot(is.numeric(scores), all(is.finite(scores)), all(scores >= 0),
            length(alpha) == 1L, is.finite(alpha), alpha > 0, alpha < 1)
  n <- length(scores)
  k <- ceiling((n + 1) * (1 - alpha))
  # Add an infinity atom implicitly; never truncate k to n or interpolate.
  if (k > n) return(Inf)
  sort(scores, partial = k)[k]
}

fit_outcome_model <- function(training) {
  stopifnot(all(c(0, 1) %in% training$treatment), !anyDuplicated(training$id))
  lm(improvement_week12 ~ treatment + baseline_score + age + biomarker,
     data = training, na.action = na.fail)
}

calibrate_by_arm <- function(model, calibration, alpha = 0.10) {
  stopifnot(all(calibration$treatment %in% c(0, 1)),
            !anyDuplicated(calibration$id))
  fitted <- if (nrow(calibration)) as.numeric(predict(model, newdata = calibration)) else numeric(0)
  scores <- abs(calibration$improvement_week12 - fitted)
  do.call(rbind, lapply(0:1, function(a) {
    arm_scores <- scores[calibration$treatment == a]
    data.frame(treatment = a, n_cal = length(arm_scores), alpha = alpha,
               rank = ceiling((length(arm_scores) + 1) * (1 - alpha)),
               radius = conformal_radius(arm_scores, alpha))
  }))
}

predict_conformal <- function(model, calibration_table, newdata) {
  stopifnot(all(newdata$treatment %in% c(0, 1)),
            identical(sort(calibration_table$treatment), 0:1),
            all(calibration_table$radius >= 0))
  center <- as.numeric(predict(model, newdata = newdata))
  radius <- calibration_table$radius[match(newdata$treatment, calibration_table$treatment)]
  data.frame(id = newdata$id, treatment = newdata$treatment,
             method = "Split conformal", center = center,
             lower = center - radius, upper = center + radius)
}

predict_model_based <- function(model, newdata, alpha = 0.10) {
  stopifnot(alpha > 0, alpha < 1)
  interval <- predict(model, newdata = newdata, interval = "prediction", level = 1 - alpha)
  data.frame(id = newdata$id, treatment = newdata$treatment,
             method = "Model-based", center = interval[, "fit"],
             lower = interval[, "lwr"], upper = interval[, "upr"], row.names = NULL)
}

assert_disjoint_cohorts <- function(training, calibration, test) {
  ids <- c(training$id, calibration$id, test$id)
  if (anyNA(ids) || anyDuplicated(ids)) stop("Patient IDs overlap across cohorts or are missing.")
  invisible(TRUE)
}

evaluate_intervals <- function(intervals, test) {
  stopifnot(!anyDuplicated(test$id))
  index <- match(intervals$id, test$id)
  stopifnot(!anyNA(index), all(intervals$lower <= intervals$upper),
            all(intervals$treatment == test$treatment[index]))
  outcome <- test$improvement_week12[index]
  stopifnot(all(is.finite(outcome)))
  covered <- outcome >= intervals$lower & outcome <= intervals$upper
  width <- intervals$upper - intervals$lower
  # Biomarker strata are descriptive diagnostics, not calibrated groups.
  groups <- list(Overall = rep(TRUE, nrow(intervals)),
                 Control = intervals$treatment == 0,
                 Investigational = intervals$treatment == 1,
                 Biomarker_nonpositive = test$biomarker[index] <= 0,
                 Biomarker_positive = test$biomarker[index] > 0)
  do.call(rbind, lapply(unique(intervals$method), function(method) {
    do.call(rbind, lapply(names(groups), function(group) {
      keep <- intervals$method == method & groups[[group]]
      n <- sum(keep)
      data.frame(method = method, group = group, n_test = n,
                 coverage = if (n) mean(covered[keep]) else NA_real_,
                 mean_width = if (n) mean(width[keep]) else NA_real_,
                 uninformative_fraction = if (n) mean(!is.finite(width[keep])) else NA_real_)
    }))
  }))
}
