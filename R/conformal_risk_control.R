# Patient-wise missed-event fraction, bounded by one.
ae_columns <- paste0("ae_", c("nausea", "fatigue", "rash", "diarrhea", "headache"))
ae_predictors <- c("treatment", "age", "baseline_score", "biomarker")
check_ae_matrix <- function(x, probabilities = FALSE) {
  stopifnot(is.matrix(x), is.numeric(x) || is.logical(x), ncol(x) == 5L,
            all(is.finite(x)), all(x >= 0 & x <= 1))
  if (!probabilities) stopifnot(all(x %in% c(0, 1)))
}
missed_event_loss <- function(y, sets) {
  check_ae_matrix(y); check_ae_matrix(sets)
  stopifnot(identical(dim(y), dim(sets)))
  rowSums(y * (!sets)) / pmax(1, rowSums(y))
}
fit_ae_models <- function(training) {
  check_ae_matrix(as.matrix(training[, ae_columns]))
  lapply(ae_columns, function(label) {
    y <- training[[label]]
    # Training-only constant fallback for absent classes or unstable fits.
    fallback <- (sum(y) + 0.5) / (length(y) + 1)
    warned <- FALSE
    fit <- if (length(unique(y)) < 2) NULL else tryCatch(
      withCallingHandlers(glm(reformulate(ae_predictors, response = label),
        data = training, family = binomial(), na.action = na.fail),
        warning = function(w) { warned <<- TRUE; invokeRestart("muffleWarning") }),
      error = function(e) NULL)
    use_constant <- is.null(fit) || warned || !isTRUE(fit$converged) ||
      any(!is.finite(coef(fit)))
    list(fit = if (use_constant) NULL else fit, constant = fallback,
         fallback = use_constant, label = label)
  })
}
predict_ae <- function(models, newdata) {
  # Restrict prediction input to pretreatment covariates and assigned arm.
  x <- newdata[, ae_predictors, drop = FALSE]
  stopifnot(nrow(x) > 0, all(is.finite(as.matrix(x))))
  ans <- vapply(models, function(m) {
    if (m$fallback) rep(m$constant, nrow(x)) else
      as.numeric(predict(m$fit, newdata = x, type = "response"))
  }, numeric(nrow(x)))
  ans <- matrix(ans, nrow = nrow(x), ncol = 5,
                dimnames = list(NULL, ae_columns))
  check_ae_matrix(ans, TRUE)
  ans
}
select_ae_threshold <- function(prob, y, alpha = 0.1,
                                method = c("CRC", "Empirical", "Fixed"),
                                grid = seq(0, 1, length.out = 201)) {
  method <- match.arg(method)
  check_ae_matrix(prob, TRUE); check_ae_matrix(y)
  stopifnot(identical(dim(prob), dim(y)), length(alpha) == 1,
            is.finite(alpha), alpha > 0, alpha < 1,
            length(grid) >= 2, all(is.finite(grid)), grid[1] == 0,
            tail(grid, 1) == 1, all(diff(grid) > 0))
  n <- nrow(y)
  risk_at <- function(lambda) {
    if (!n) NA_real_ else mean(missed_event_loss(y, prob >= 1 - lambda))
  }
  fallback <- FALSE
  if (method == "Fixed") lambda <- 0.5 else if (!n) {
    lambda <- 1; fallback <- TRUE
  } else {
    risks <- vapply(grid, risk_at, numeric(1))
    criterion <- if (method == "CRC") (n * risks + 1) / (n + 1) else risks
    eligible <- which(criterion <= alpha)
    if (length(eligible)) lambda <- grid[eligible[1]] else {
      lambda <- 1; fallback <- TRUE
    }
  }
  risk <- risk_at(lambda)
  data.frame(method = method, n_cal = n, lambda = lambda,
             probability_threshold = 1 - lambda, calibration_risk = risk,
             corrected_risk = if (n) (n * risk + 1) / (n + 1) else NA_real_,
             safe_all_labels_fallback = fallback)
}
calibrate_ae_by_arm <- function(prob, y, treatment, alpha = 0.1) {
  stopifnot(length(treatment) == nrow(y), all(treatment %in% 0:1))
  do.call(rbind, lapply(c("Fixed", "Empirical", "CRC"), function(method) {
    do.call(rbind, lapply(0:1, function(arm) {
      idx <- which(treatment == arm)
      z <- select_ae_threshold(prob[idx, , drop = FALSE], y[idx, , drop = FALSE],
                               alpha, method)
      z$treatment <- arm; z
    }))
  }))
}
predict_ae_sets <- function(prob, treatment, calibration, method) {
  check_ae_matrix(prob, TRUE)
  tab <- calibration[calibration$method == method, ]
  stopifnot(nrow(tab) == 2, !anyDuplicated(tab$treatment),
            length(treatment) == nrow(prob), all(treatment %in% tab$treatment))
  thresholds <- tab$probability_threshold[match(treatment, tab$treatment)]
  prob >= thresholds
}
evaluate_ae_sets <- function(y, sets, patients, method) {
  loss <- missed_event_loss(y, sets)
  groups <- list(Overall = seq_len(nrow(y)), Control = which(patients$treatment == 0),
    Investigational = which(patients$treatment == 1),
    Biomarker_nonpositive = which(patients$biomarker <= 0),
    Biomarker_positive = which(patients$biomarker > 0))
  do.call(rbind, lapply(names(groups), function(g) {
    i <- groups[[g]]; event <- rowSums(y[i, , drop = FALSE]) > 0
    data.frame(method = method, group = g, n_test = length(i),
      risk = if (length(i)) mean(loss[i]) else NA_real_,
      mean_set_size = if (length(i)) mean(rowSums(sets[i, , drop = FALSE])) else NA_real_,
      all_labels_fraction = if (length(i)) mean(rowSums(sets[i, , drop = FALSE]) == 5) else NA_real_,
      no_event_fraction = if (length(i)) mean(!event) else NA_real_,
      event_positive_risk = if (any(event)) mean(loss[i][event]) else NA_real_)
  }))
}
run_crc_experiment <- function(n_train = 1000L, n_cal = 400L, n_test = 2000L,
                               alpha = 0.1, seed = 20261025L) {
  cohorts <- lapply(0:2, function(i) {
    d <- simulate_trial(c(n_train, n_cal, n_test)[i + 1], seed = seed + i)
    d$id <- paste0(c("train_", "cal_", "test_")[i + 1], d$id); d
  })
  train <- cohorts[[1]]; cal <- cohorts[[2]]; test <- cohorts[[3]]
  stopifnot(!anyDuplicated(c(train$id, cal$id, test$id)))
  models <- fit_ae_models(train)
  pc <- predict_ae(models, cal); pt <- predict_ae(models, test)
  yc <- as.matrix(cal[, ae_columns]); yt <- as.matrix(test[, ae_columns])
  calibration <- calibrate_ae_by_arm(pc, yc, cal$treatment, alpha)
  metrics <- list(); predictions <- list()
  for (method in c("Fixed", "Empirical", "CRC")) {
    sets <- predict_ae_sets(pt, test$treatment, calibration, method)
    metrics[[method]] <- evaluate_ae_sets(yt, sets, test, method)
    predictions[[method]] <- data.frame(id = test$id, treatment = test$treatment,
      biomarker = test$biomarker, method = method, loss = missed_event_loss(yt, sets),
      set_size = rowSums(sets), setNames(as.data.frame(pt), paste0("prob_", ae_columns)),
      setNames(as.data.frame(sets), paste0("include_", ae_columns)), yt)
  }
  list(metrics = do.call(rbind, metrics), calibration = calibration,
       predictions = do.call(rbind, predictions),
       model_diagnostics = data.frame(label = ae_columns,
         constant_fallback = vapply(models, function(m) m$fallback, logical(1))))
}
summarize_crc <- function(metrics, alpha = 0.1) {
  keys <- interaction(metrics$n_cal_total, metrics$method, metrics$group, drop = TRUE)
  do.call(rbind, lapply(split(metrics, keys), function(d) {
    z <- d[1, c("n_cal_total", "method", "group")]; z$replicates <- nrow(d)
    for (field in c("risk", "mean_set_size", "all_labels_fraction", "no_event_fraction", "event_positive_risk")) {
      v <- d[[field]][is.finite(d[[field]])]; n <- length(v)
      z[[paste0(field, "_evaluated_replicates")]] <- n
      z[[field]] <- if (n) mean(v) else NA_real_
      se <- if (n > 1) sd(v) / sqrt(n) else NA_real_
      z[[paste0(field, "_mcse")]] <- se
      if (field == "risk") {
        margin <- if (n > 1) qt(0.975, n - 1) * se else NA_real_
        z$risk_mc_lower <- max(0, mean(v) - margin)
        z$risk_mc_upper <- min(1, mean(v) + margin)
        z$fraction_replicates_test_risk_above_alpha <- mean(v > alpha)
      }
    }
    z
  }))
}
