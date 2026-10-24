analyze_trial <- function(data, alpha = 0.05) {
  stopifnot(alpha > 0, alpha < 1)
  fit <- lm(improvement_week12 ~ treatment + baseline_score + age + biomarker,
            data = data, na.action = na.fail)
  tab <- coef(summary(fit))["treatment", ]
  interval <- confint(fit, "treatment", level = 1 - alpha)
  data.frame(estimate = unname(tab["Estimate"]),
             standard_error = unname(tab["Std. Error"]),
             lower = interval[1], upper = interval[2],
             p_value = unname(tab["Pr(>|t|)"]),
             reject = unname(tab["Pr(>|t|)"]) < alpha,
             row.names = NULL)
}

baseline_table <- function(data) {
  variables <- c("age", "baseline_score", "biomarker")
  do.call(rbind, lapply(0:1, function(a) {
    subset <- data[data$treatment == a, ]
    data.frame(arm = if (a == 0) "Control" else "Investigational",
               variable = variables, n = nrow(subset),
               mean = vapply(subset[variables], mean, numeric(1)),
               sd = vapply(subset[variables], sd, numeric(1)), row.names = NULL)
  }))
}

safety_table <- function(data) {
  variables <- grep("^ae_", names(data), value = TRUE)
  do.call(rbind, lapply(0:1, function(a) {
    subset <- data[data$treatment == a, ]
    counts <- colSums(subset[variables])
    data.frame(arm = if (a == 0) "Control" else "Investigational",
               event = variables, patients_with_event = unname(counts),
               denominator = nrow(subset), percent = 100 * unname(counts) / nrow(subset))
  }))
}
