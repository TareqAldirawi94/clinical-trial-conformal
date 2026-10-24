# Adverse-event prediction with conformal risk control

This educational simulation adds multilabel adverse-event prediction to the trial
portfolio. It uses the existing five binary AE labels. It contains no real patient
data, severity grades, event timing, censoring, or treatment discontinuation.
It does not model a Phase I dose-escalation design or a confirmatory safety analysis.

## Target and methods

For patient i, let Y_i be the observed event labels and C_lambda(X_i) the predicted
set. The loss is |Y_i \ C_lambda(X_i)| / max(1, |Y_i|). Patients with no events
contribute zero. Each patient, rather than each event, has equal weight.
The target is expected loss at most alpha = 0.10.

Five logistic regressions use assigned treatment, age, baseline score and biomarker.
Training has 1,000 patients; calibration has 40, 100 or 400; test has 2,000.
Each cohort is independent with balanced allocation. These are methodological
simulation cohorts, not a claim that one 240-person trial supplies this data.
Shared latent susceptibility creates correlated labels and is not a predictor.
A fit warning, nonconvergence, nonfinite coefficient, or absent response class
triggers a training-only smoothed prevalence fallback, recorded in diagnostics.

All methods use the same fitted probabilities and evaluation patients:

- Fixed: include labels with probability at least 0.50.
- Empirical: select the smallest lambda whose calibration loss is at most alpha.
- CRC: select the smallest lambda satisfying (n * mean_loss + 1)/(n + 1) <= alpha.

The set is {j: p_j >= 1-lambda}. The fixed grid has 201 equally spaced values from
0 to 1 and is specified before calibration. Larger lambda gives larger sets and
nonincreasing loss. Ties are included. The finite-sample correction uses B=1.
If no candidate satisfies the criterion, including when an arm has fewer than
9 calibration patients, return lambda=1: all labels, with deterministically zero
loss. The same safe endpoint is used for an empty calibration arm.

## What the guarantee means

Calibration is separate by treatment arm, using the number of patients in that
arm in the correction. This avoids treating a fixed balanced allocation as an
unrestricted pooled IID sample. Under the simulated data-generating process,
calibration patients and a future patient are exchangeable within each arm,
conditional on the independently fitted model. The monotone bounded-loss CRC
result gives expected future loss at most alpha within each arm, averaging over
calibration and future patients. Any fixed mixture of these arms inherits that
expectation bound. This is not a simultaneous bound on both realized arm risks.

A realized calibration set can yield test risk above alpha. The reported fraction
of replications exceeding alpha is a diagnostic, not a nominal error rate.
This is not a 90% probability that every calibration set has risk <=0.1, a
patient-specific guarantee, or control of drug AE incidence. Biomarker subgroup
risk and event-positive conditional risk are diagnostic; neither is separately
controlled here. No-event patients can substantially lower unconditional loss,
so both no-event fraction and event-positive risk are reported.

## Run

From the repository root, or using the configured Windows path:

```r
source("tests/test_crc.R")
source("scripts/run_crc.R")
options(crc.replicates = 200, crc.calibration_sizes = c(40, 100, 400))
source("scripts/run_crc_repeated.R")
```

For a quick smoke run first, use crc.replicates=3, then rerun with 200.
Base R is sufficient. Repeated runs overwrite the CRC outputs only.

## Read the outputs

Everything is under outputs/crc/. Start with repeated_summary.csv:

- risk and risk_mcse: mean patient loss and Monte Carlo standard error across trials.
- risk_mc_lower/upper: t-based Monte Carlo interval for the mean, clipped to [0,1].
- mean_set_size: burden of flagged events, from 0 to 5.
- all_labels_fraction: fraction receiving all five labels.
- no_event_fraction and event_positive_risk: explain the loss denominator.

Review Overall, Control, and Investigational first. A single realization is not a
validation of the expectation theorem. Compare CRC with Empirical using paired
replicate_metrics.csv rows; the default summary does not report paired differences.
CRC sets must be at least as large as Empirical sets within each arm. It may be
conservative, and weak predictors can require broad prediction sets. Do not claim
superiority without checking risk and set size together.

replicate_calibration.csv records thresholds, arm sample sizes, corrected risks,
and fallback flags. The single_predictions.csv file supports independent metric
reconstruction, including probabilities, selected labels, outcomes and patient loss.
replicate_model_diagnostics.csv records training fallbacks.
Seeds are 20261025+3*i, with offsets 0/1/2 for train/cal/test. Training and test
cohorts are shared across calibration sizes for a given replicate, so size
comparisons are correlated; replications within a size are independent simulations.

## Reference

Angelopoulos, Bates, Fisch, Lei and Schuster (2024), *Conformal Risk Control*,
ICLR. https://proceedings.iclr.cc/paper_files/paper/2024/hash/f3549ef9b5ff520a7e41ff3cc306ab2b-Abstract-Conference.html
The arm-specific application and simulated AE endpoints here are project choices.

## Validation status

This addition has static checks and executable R tests. R is unavailable in the
build environment; no new R execution or CRC numerical results are claimed.
The author subsequently supplied repeated CRC outputs, reviewed in
reports/results.md. Test logs have not been supplied; run the test suite locally
or inspect GitHub Actions before claiming that all tests pass.
