# Draft statistical analysis plan — version 0.1

Status: educational simulation specification. No real trial, protocol registration,
clinical approval, or regulatory compliance is claimed. This plan precedes numerical
results. Changes should be documented with date, reason, and effect on the estimand.

## 1. Objectives and design

Parallel-group, fixed-sample, randomized Phase II illustration: 240 synthetic adult
participants, 120 per arm, 12-week follow-up. Allocation is uniformly sampled among
balanced assignments. The simulation contains no enrollment exclusions after
randomization, nonadherence, discontinuation, deaths, or missing outcomes.

## 2. Primary estimand

- Population: eligible adults represented by the simulation distribution.
- Treatment conditions: assignment to investigational treatment versus standard care.
- Variable: week-12 clinical-score improvement, with larger values favorable.
- Intercurrent events: intended future treatment-policy strategy for treatment
  discontinuation, requiring follow-up regardless of discontinuation. Version 0.1
  contains no such events, so competing strategies cannot yet be evaluated.
- Summary: difference in population mean improvement between randomized arms.

Missing measurements are distinct from intercurrent events. Death before week 12
is not simulated; adding it would require revisiting the endpoint and estimand.
The current code rejects incomplete efficacy inputs rather than silently deleting
patients. Treatment-policy terminology alone does not solve missing-data problems.

## 3. Analysis populations

Primary efficacy population: all randomized synthetic participants, analyzed as
assigned. For this first version, everyone receives assigned treatment, so the
descriptive safety population equals the randomized population. Later versions
must define actual-exposure safety populations separately if adherence differs.

## 4. Efficacy analysis

Fit improvement_week12 ~ treatment + baseline_score + age + biomarker by ordinary
least squares. Treatment is numeric 0/1. The coefficient estimates the adjusted
investigational-minus-control effect. Use its Student-t interval with residual
degrees of freedom and a two-sided t test of coefficient zero at 0.05.
The correctly specified, homoscedastic Gaussian model supports this initial
inference. Robust SEs or alternative estimators must be specified for later
heteroscedastic/nonlinear scenarios. No transformations or covariate selection
based on observed p-values. Baseline summaries are descriptive, without tests.

One primary endpoint and one primary comparison: no multiplicity adjustment in
version 0.1. Exploratory subgroup/predictive analyses make no confirmatory claims.

## 5. Safety analysis

For each arm and each of five events, report patients with at least one event,
denominator, and percentage. Patients may contribute to multiple categories.
The indicators do not contain onset, recurrence, relatedness, or severity.
These are simplified event-incidence summaries, not complete treatment-emergent
adverse-event tables. Severity summaries are planned, not currently available.

## 6. Missing-data extension (not implemented)

Introduce missing week-12 scores with known simulation mechanisms. A candidate
primary analysis uses multiple imputation under MAR with treatment and prognostic
baseline variables, pooling estimates with Rubin's rules. Prespecify a delta-adjusted
MNAR sensitivity analysis targeting the same treatment-policy estimand. Continue
to collect outcomes after discontinuation in the simulated design. Final imputation
models, number of imputations, and delta range must be specified before that run.

## 7. Predictive extensions

CP and CRC are exploratory, separate from the primary efficacy test. See
conformal-specification.md. They must use valid data splitting and define which
population and treatment arm the calibration covers. A prediction set does not
change the primary analysis population or establish treatment benefit.

## 8. Outputs and operating characteristics

Baseline, primary efficacy, and safety tables; descriptive improvement boxplot;
planning sample-size summary; simulation operating-characteristic table. Report
Monte Carlo uncertainty, configuration, seed, replicate count, and R session.
Inspect bias, coverage, Type I error, and power across predefined scenarios.
Do not change settings solely to produce favorable reported results.

## 9. Quality checks

Balanced allocation, reproducibility, binary event values, unique IDs, failure on
missing efficacy measurements, and known additive-shift invariance of ANCOVA.
GitHub Actions runs the tests and a smoke simulation. Large-scale simulation
evaluation is separate from unit tests.
