# Four-cell Mondrian prediction comparison

## Scope

This module adds one method, `Mondrian arm x biomarker`, to the existing model-based
and arm-specific split conformal comparison. It uses the same fitted linear model,
training data, calibration data, and test patients for all methods within each run.
The original scripts and their outputs are retained. New files go to outputs/mondrian/.
Arm-specific adverse-event CRC is implemented separately; see crc-guide.md.

## Fixed groups and calibration

The partition is Control/nonpositive biomarker, Control/positive biomarker,
Investigational/nonpositive biomarker, and Investigational/positive biomarker.
Zero is nonpositive. The threshold zero is a fixed simulation definition, not an
estimated clinical biomarker cutoff. The split was chosen to study the known
variance mechanism and observed diagnostic gap; this is a methodological follow-up,
not independent confirmation of a clinically discovered subgroup.

Within cell g, let n_g be its calibration count. Use the
ceiling((n_g+1)*(1-alpha))-th absolute residual, or infinity when that rank exceeds
n_g. At alpha=0.10, at least 9 observations are needed for a finite radius.
Missing cells remain in the calibration table and receive an infinite radius.
There is no fallback to pooling: that would change the group guarantee.

Under exchangeability within the fixed cells and a model fitted independently of
calibration, coverage targets a future patient in each cell, averaging over the
calibration data. It does not promise coverage conditional on every realized
calibration sample, every exact biomarker value, or simultaneous coverage of all
future patients. This is a group-conditional prediction guarantee, not a statement
about treatment-effect confidence intervals or treatment safety.

## Repeated experiment

Defaults: training n=1000, test n=2000, 200 repetitions per scenario and calibration
size. Total calibration sizes are 40, 100, and 400. Each arm has half the calibration
patients, but biomarker cell counts are random, averaging roughly 10, 25, and 100.
Two scenarios are inherited unchanged from the previous CP experiment. At n_cal=400,
the existing two methods reproduce the previous experiment's seed schedule/settings.
Cross-size runs share training and test seeds; do not treat sizes as independent
when computing comparisons. Methods within a repetition are paired.

The 400-patient case assesses subgroup coverage and width adaptation. Smaller
calibration sizes expose local support limitations. All three methods are evaluated
overall, by arm, by biomarker sign, and in each of the four intersection cells.
There is no assumption that Mondrian always improves width or empirical coverage.
In the linear scenario, splitting can mainly add calibration uncertainty. In the
heteroscedastic scenario, different radii may better reflect subgroup variability.

## Run from RStudio

```r
source("tests/test_mondrian.R")
source("scripts/run_mondrian_prediction.R")
options(mondrian.replicates = 200,
        mondrian.calibration_sizes = c(40, 100, 400))
source("scripts/run_mondrian_repeated.R")
```

To run only the main comparison first, use `mondrian.calibration_sizes = 400`.
The repeated script overwrites its own Mondrian result files; rerun with all three
sizes to produce a combined output. It never writes into outputs/conformal/.
For smoke checks use 3 repetitions, which are not sufficient for scientific claims.

## Outputs and interpretation

- repeated_summary.csv: coverage, width, repetition-level Monte Carlo uncertainty,
  uninformative fraction, and fraction of repetitions with infinite mean width.
- replicate_metrics.csv: performance for each repetition and group.
- replicate_calibration.csv: every cell's count, quantile rank, and radius.
- repeated_configuration.csv and session-info.txt: reproduction information.
- single_run_metrics.csv, calibration_details.csv, prediction_intervals.csv,
  configuration.csv: one fit/calibration example per scenario at default n_cal=400.

Infinite widths are mathematically appropriate when local support is inadequate.
The overall mean width is infinite if any contributing interval has infinite width.
No finite-only width is substituted. Width MCSE is NA when widths are nonfinite.
The uninformative fraction quantifies how many patients receive such intervals.
Coverage summaries exclude empty *test* cells, explicitly reporting the number of
excluded repetitions. Calibration cells are never dropped. Empty test cells should
be unusual with the default test size, but the handling is explicit.

The reported coverage Monte Carlo intervals describe simulation precision using
independent repetitions within each scenario/size. They are not theorem-derived
high-probability coverage bounds. Multiple displayed cells are correlated and the
intervals are not simultaneous. Treat comparisons as descriptive simulation findings.

## Validation status

The prior arm-specific module ran successfully on the user's computer. This new
module has static checks only in the creation environment, where R is unavailable.
Run the included tests and check GitHub Actions before interpreting new results.
Tests cover cell boundaries, exact ranks, empty/small cells, cell isolation,
prediction-label separation, patient matching, retention of infinite widths, and
agreement of the original two methods with the prior experiment.
