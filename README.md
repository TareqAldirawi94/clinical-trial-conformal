# Clinical Trial Analysis with Conformal Prediction and Risk Control

An R portfolio project connecting **randomized Phase II trial analysis** with
**individual-outcome prediction** and **multilabel adverse-event risk control**.
All patient data are simulated. The project demonstrates statistical programming,
analysis planning, simulation evaluation, and interpretation of uncertainty.

## Questions addressed

| Question | Analysis | Evaluation |
|---|---|---|
| Does treatment improve the mean week-12 outcome? | Covariate-adjusted ANCOVA in a 240-person randomized trial | Type I error, power, bias, RMSE, confidence-interval coverage |
| How uncertain is a new patient's outcome? | Model-based, arm-specific split conformal, and Mondrian prediction intervals | Coverage and width overall, by arm, and by biomarker subgroup |
| Which adverse-event labels should be included in a prediction set? | Five logistic models with fixed, empirically tuned, or CRC thresholds | Patient-wise missed-event fraction and prediction-set size |

Treatment-effect confidence intervals, individual prediction intervals, and
expected prediction loss answer different questions. CP and CRC do not establish
drug efficacy or drug safety.

## Selected results

The efficacy simulation used 1,000 replications per scenario. Predictive experiments
used 200 replications, independent training/calibration/test cohorts, and a 90%
coverage target or a 10% risk target.

- **Trial analysis:** 3.8% null rejection and 79.6% power for the simulated
  three-point treatment effect. Monte Carlo uncertainty is reported in the results.
- **Subgroup prediction:** in the nonlinear, heteroscedastic scenario with 400
  calibration patients, arm-specific CP covered 90.16% overall but only 82.75%
  in the positive-biomarker subgroup. Four-cell Mondrian calibration achieved
  90.44% in that subgroup and reduced overall mean width from 35.89 to 32.95.
- **Adverse-event CRC:** with 400 calibration patients, mean missed-event risk was
  9.07% (95% Monte Carlo interval 8.86%–9.27%), with 3.79 of five labels included
  on average. A biomarker subgroup still had 11.80% risk: arm-specific control
  does not imply control in every subgroup.

![CRC risk and prediction-set size](reports/figures/crc-comparison.png)

Read the [results report](reports/results.md) for comparisons, uncertainty and
limitations. [Reference CSVs](results/reference/) and their provenance are committed
so readers can inspect results without rerunning the simulations.

## Run the project

The analysis uses base/recommended R packages, with no extra R packages required.
Open `clinical-trial-conformal.Rproj` in RStudio, then run:

```r
source("tests/run_tests.R")
source("tests/test_conformal.R")
source("tests/test_mondrian.R")
source("tests/test_crc.R")
source("scripts/run_trial.R")
source("scripts/run_conformal_prediction.R")
source("scripts/run_mondrian_prediction.R")
source("scripts/run_crc.R")
```

For full repeated simulations, run from the repository root in a terminal:

```sh
Rscript scripts/run_operating_characteristics.R 1000
Rscript scripts/run_conformal_repeated.R 200
Rscript scripts/run_mondrian_repeated.R 200
Rscript scripts/run_crc_repeated.R 200
```

Results are written to `outputs/`, which is excluded from Git. Seeds are recorded
in the scripts and generated configuration files. See [START_HERE.md](START_HERE.md)
for Windows setup and first-push instructions.

## Repository map

| Directory | Contents |
|---|---|
| `R/` | Simulation, ANCOVA, conformal calibration, CRC and evaluation functions |
| `scripts/` | Reproducible analysis entry points |
| `tests/` | Statistical edge cases, data separation, invariance and integration checks |
| `docs/` | Analysis plan, variable dictionary, method specifications and references |
| `reports/` | Results narrative, figures and optional Quarto reports |
| `results/reference/` | Reviewed summary outputs and calibration records |
| `.github/workflows/` | Automated R tests and smoke simulations |

## Scope and validation status

The simulation represents a hypothetical Phase II setting. It does not implement
Phase I dose escalation, Phase III confirmatory multiplicity, real patient data,
missing-data sensitivity analyses or a regulatory submission workflow.
Predictive experiments use 1,000 training and 2,000 test patients plus separate
calibration cohorts; these are not all drawn from the 240-person efficacy trial.

The author supplied completed R simulation outputs. The baseline test pass was
reported; subsequent test logs were not supplied. Reference-output arithmetic and
calibration checks were reviewed. The packaging environment has no R runtime, so
current test execution should be verified through the supplied tests and GitHub
Actions. No CI pass is claimed before the first workflow run.

## Methods and documentation

- [Statistical analysis plan](docs/statistical-analysis-plan.md)
- [Conformal specification](docs/conformal-specification.md)
- [Mondrian guide](docs/mondrian-guide.md)
- [CRC guide](docs/crc-guide.md)
- [Selected references](docs/references.md)

Future work includes missing outcomes, distribution shift and a suitable real-data
application. These are not part of the completed simulation results.
