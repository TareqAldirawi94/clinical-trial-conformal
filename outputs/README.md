# Generated outputs

Run scripts from the repository root. Outputs are synthetic and ignored by Git,
except for this file.

- `run_trial.R` writes simulated patient data, baseline and safety tables,
  efficacy results, an approximate sample-size calculation, a plot, and session
  information.
- `run_operating_characteristics.R` writes `operating_characteristics.csv`.
- `run_conformal_prediction.R` and `run_conformal_repeated.R` write to
  `outputs/conformal/`.
- `run_mondrian_prediction.R` and `run_mondrian_repeated.R` write to
  `outputs/mondrian/`.
- `run_crc.R` and `run_crc_repeated.R` write to `outputs/crc/`.

Committed reference copies of the repeated-experiment summaries are in
`results/reference/`. Do not interpret any generated values as findings from a
real trial.
