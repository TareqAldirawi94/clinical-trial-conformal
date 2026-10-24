# Conformal extensions: implementation specification

Status: model-based, arm-specific split conformal, four-cell Mondrian prediction
and arm-specific CRC are implemented. Conformalized quantile regression is deferred.
Read the module guides and reports/results.md for settings and results.

## Data separation

Start with three independent synthetic cohorts drawn from the same target law:
training, calibration, and test. This deliberately isolates mathematical calibration
from small-trial model fitting. Report all cohort sizes and avoid implying that the
240-person efficacy trial alone trained a large predictive model. Later study the
realistic setting of limited trial-only splits and their efficiency costs.

Models and hyperparameters are fixed using training data and internal validation.
Do not tune models on the calibration outcomes. Freeze predictions before evaluating
test labels. Test labels may be used only for evaluation. Calibration and future
patients must be exchangeable within the population/arm being claimed. Distribution
shift scenarios are empirical stress tests, not automatically valid extensions.

## 1. Split conformal efficacy intervals

Train a conditional mean model m(x,a) using training data. For each treatment arm a,
compute calibration scores |Y_i - m(X_i,a)|. For n_a calibration patients, set
k_a = ceiling((n_a + 1) * (1 - alpha_CP)). Take the k_a-th smallest calibration
score if k_a <= n_a; otherwise use infinity. The interval is m(x,a) +/- q_a.
Use an order statistic directly, not interpolated software quantiles. At n_a=0,
return an uninformative interval. This handles ties conservatively.

Under the corresponding exchangeability and fixed-training conditions, the target
is marginal prediction coverage within arm a, averaged over calibration and the
future patient. It is not pointwise conditional coverage for each covariate vector.
Intervals for treatment-arm outcomes are not intervals for individual treatment
effects. Start with alpha_CP=0.10 and add 0.05 and 0.20 as sensitivity settings.

Baselines: model-based prediction intervals (not mean confidence intervals), then
conformalized quantile regression. Evaluate coverage, width, and the frequency of
uninformative intervals. Subgroup evaluation does not itself establish subgroup
validity. If adding group-specific calibration, prespecify groups and report counts.

## 2. Adverse-event prediction model and nested sets

Fit five logistic models on training data to estimate event probabilities p_j(x,a).
These are prediction models, not estimates of a patient's causal treatment benefit.
For lambda on a prespecified grid from 0 to 1, define
C_lambda(x,a) = {j : p_j(x,a) >= 1 - lambda}.
Increasing lambda expands the set. Lambda=1 includes all event categories.
Any absent-class training failure must have a defined fallback before calibration.

For observed event vector y, use
L(C,y) = number of experienced events absent from C / max(1, number experienced).
This bounded [0,1] loss decreases with lambda. No-event patients contribute zero.

## 3. CRC threshold

Within each treatment arm, use its calibration count n and compute Rhat_n(lambda),
the mean loss in that arm. Calibrate each arm separately.
Select the smallest lambda on the fixed finite grid satisfying

    (n * Rhat_n(lambda) + 1) / (n + 1) <= alpha_CRC.

If none qualifies, return lambda=1, whose loss is identically zero. This terminal
safety rule also handles n=0. Specify alpha_CRC=0.10 separately from efficacy test
alpha=0.05 and alpha_CP=0.10; identical notation must not imply identical targets.
Evaluate the standard CRC theorem's exchangeability, boundedness, and monotonicity
conditions against the actual implementation before asserting a guarantee.

Target: expected future-patient missed-event fraction, averaged over calibration
and the future patient. It is not a high-probability bound conditional on the fitted
threshold. It neither controls the drug's event incidence nor guarantees every
event's recall. Conditional-on-event loss and severe-event miss rate are useful
additional descriptive metrics, but are not covered by this unconditional loss.

## 4. Comparisons and evaluation

Compare fixed probability threshold 0.5, an empirical-risk threshold tuned on
the same calibration data as CRC, and CRC. Keep training/tuning budgets explicit. Fit all models
without test-label access. Report average loss, average set size, frequency of
all-event sets, no-event patient proportion, and arm/subgroup descriptive results.
Repeat across calibration samples; report the mean risk and its Monte Carlo SE.
The percentage of repetitions whose population risk exceeds alpha is a diagnostic,
not a quantity that ordinary expected-risk CRC promises to make zero.

## 5. Included tests

- Exact CP rank calculation, ties, n=0, and rank greater than n.
- Nested event sets, inclusion of all events at the endpoint, and monotone loss.
- Zero-event patients, all-event patients, zero calibration rows, and no feasible
  CRC threshold.
- No patient leakage across training, calibration, and evaluation.
- Independent simulation of nominal coverage/expected risk with Monte Carlo error.

## 6. Deferred extensions

Severity-weighted missed-event loss, additional CRC subgroup calibration,
rare-event behavior, missing safety outcomes, censoring, and population shift.
Each changes the data requirements or interpretation and needs an explicit argument.
