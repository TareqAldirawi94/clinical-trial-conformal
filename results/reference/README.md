# Reference simulation outputs

Reference summaries produced by the scripts in `scripts/`, run on R 4.6.1
(Windows). Each file was regenerated on 2026-11-03 and is byte-identical to the
committed version; `provenance.json` records the generating script and the
SHA-256 checksum of each file. `scripts/compare_to_reference.R` repeats the
comparison against fresh output.

- cp_summary.csv: two scenarios, two methods, 200 replications each, n_cal=400.
- mondrian_summary.csv: three methods and n_cal=40,100,400, 200 replications.
- crc_summary.csv: three methods and n_cal=40,100,400, 200 replications.
- efficacy_summary.csv: null and alternative scenarios, 1,000 replications each.
- *_calibration.csv: calibration records supporting threshold and rank checks.

Training n=1000 and test n=2000 for predictive experiments. Summary files retain
Monte Carlo uncertainty. Patient-level predictions are not committed.

Rerunning analyses writes to outputs/, leaving these reference files unchanged.
Review fresh results before deliberately replacing any reference snapshot.
See ../../reports/results.md for findings and validation limits.