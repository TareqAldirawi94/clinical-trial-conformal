# Reference simulation outputs

These are unchanged CSV outputs supplied by the project author from local R runs
and reviewed on 2026-10-24. `provenance.json` records original upload names and
SHA-256 checksums. They are snapshots, not outputs from a new execution here.

- cp_summary.csv: two scenarios, two methods, 200 replications each, n_cal=400.
- mondrian_summary.csv: three methods and n_cal=40,100,400, 200 replications.
- crc_summary.csv: three methods and n_cal=40,100,400, 200 replications.
- *_calibration.csv: calibration records supporting threshold and rank checks.

Training n=1000 and test n=2000 for predictive experiments. Summary files retain
Monte Carlo uncertainty. Clinical efficacy operating characteristics are reported
in the results narrative from console output; their original CSV is not included.
Patient-level predictions are excluded from this committed reference snapshot.

Rerunning analyses writes to outputs/, leaving these reference files unchanged.
Review fresh results before deliberately replacing any reference snapshot.
See ../../reports/results.md for findings and validation limits.
