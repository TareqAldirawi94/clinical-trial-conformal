# Interpreting the conformal prediction comparison

## Implemented design

This module uses a new independent predictive experiment, separate from the
240-person efficacy analysis. Each repetition has 1,000 training patients,
400 calibration patients (200 per randomized arm), and 2,000 test patients
(1,000 per arm). The default target coverage is 90% (alpha=0.10).
Training, calibration, and test cohorts use separate seeds and distinct IDs.
Settings are in R/prediction_experiment.R, function prediction_config().

The cohort generator samples independent patients with complete balanced
randomization. Conditional on assignment within each arm, calibration and future
outcomes follow the same law in each scenario. The prediction model uses only the
training cohort. Test outcomes are not passed to the prediction functions.
This is not an external-control borrowing analysis and assumes no cohort shift.

## Methods

Both methods use exactly the same linear mean model trained on the same data:

- Model-based: `predict.lm(interval="prediction")`, using the Gaussian constant-
  variance linear-model assumptions. This includes future-outcome variability.
- Split conformal: absolute calibration residuals, calibrated separately by arm.
  With n=200 per arm and alpha=0.10, k=ceiling(201*0.90)=181. The radius is
  the 181st smallest residual, not the interpolated empirical 90th percentile.
  If k exceeds n, the radius is infinite. No interpolation or clipping is used.

Only conformal uses calibration outcomes; report that additional data budget when
comparing methods. The shared training model isolates the calibration difference,
not optimal performance under every possible use of all available data.

## Scenarios

1. `linear`: correctly specified Gaussian linear conditional mean with SD 8.
2. `nonlinear_heteroscedastic`: adds 4*(biomarker^2-1) to the conditional mean;
   residual SD is 12 for positive biomarker and 4 otherwise. The fitted linear
   model omits the nonlinear term and varying variance. Train/calibration/test
   share this same law; model misspecification is not distribution shift.

The second scenario illustrates limitations of both the model-based assumptions
and of interpreting marginal conformal coverage as covariate-conditional coverage.
Do not assume conformal must always be narrower or model-based coverage must always
fail overall: examine the actual output.

## Files

- single_run_metrics.csv: coverage/width from one fit and calibration sample.
- calibration_details.csv: arm counts, rank, alpha, and calibrated radius.
- prediction_intervals.csv: patient intervals and outcomes (attached after prediction).
- individual_prediction_intervals.png: first 30 test patients per method/scenario.
- replicate_metrics.csv: every repeat's performance by method and group.
- repeated_summary.csv: averages and Monte Carlo uncertainty across repetitions.
- configuration.csv / repeated_configuration.csv: cohort sizes and base seed.
- session-info.txt / repeated-session-info.txt: software environment.

## Interpret the summary

`mean_coverage` averages the per-repetition test coverage. `coverage_mcse` is the
standard deviation across repetitions divided by sqrt(number of repetitions),
accounting for variation from training, calibration, and evaluation sampling.
The Monte Carlo interval uses a t multiplier and is descriptive, not a conformal
confidence bound. Repetition, not an individual pooled test patient, is the unit
for this uncertainty calculation. `mean_width` is the average interval width;
`width_mcse` uses the same repetition-level principle. Infinite intervals are
retained in average width, with undefined width MCSE reported as NA.

The arm-specific conformal guarantee averages over calibration and a future patient
within each arm. It does not promise at least 90% coverage for every realized
calibration set. At n=200, continuous-score coverage is constrained by rank
resolution (181/201, approximately 90.05%, in the ideal exchangeable case).
Finite test sets and finitely many repetitions add Monte Carlo error.

Biomarker strata are diagnostic only: we calibrated by arm, not by biomarker.
Low coverage in a biomarker stratum does not contradict an arm-marginal guarantee.
Overlapping biomarker/arm summaries must not be treated as independent estimates.
The output averages subgroup rates equally over repetitions; it is not a
patient-count-weighted pooled subgroup rate.

## Scope and validation

This milestone adds CP, not CRC or individual treatment-effect prediction.
R is unavailable in the artifact-creation environment, so the new tests have not
been executed there. Run tests/test_conformal.R and inspect GitHub Actions. The
unit tests cover ranks, ties, empty arms, disjoint IDs, independent arm calibration,
label leakage, patient matching, prediction-versus-mean intervals, and translation
invariance. Monte Carlo coverage assessment is a separate scientific check.
