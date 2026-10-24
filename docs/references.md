# Selected references and their roles

1. ICH E9(R1), *Addendum on Estimands and Sensitivity Analysis in Clinical Trials*.
   [FDA guidance page](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/e9r1-statistical-principles-clinical-trials-addendum-estimands-and-sensitivity-analysis-clinical).
   Role: distinguish estimand, estimator, intercurrent events, and sensitivity analyses.
   Reading this guidance does not establish regulatory compliance of this portfolio.
2. Lei and Candès (2021), *Conformal Inference of Counterfactuals and Individual
   Treatment Effects*, JRSS B 83(5), 911–938.
   https://arxiv.org/abs/2006.06138
   Role: causal prediction background; individual treatment-effect inference is deferred.
3. Angelopoulos, Bates, Fisch, Lei, and Schuster (2024), *Conformal Risk Control*, ICLR.
   https://proceedings.iclr.cc/paper_files/paper/2024/hash/f3549ef9b5ff520a7e41ff3cc306ab2b-Abstract-Conference.html
   Role: bounded monotone prediction-loss calibration.
4. Zhu, Yang, and Wang (2025), *Enhancing Statistical Validity and Power in Hybrid
   Controlled Trials: A Randomization Inference Approach with Conformal Selective
   Borrowing*, ICML.
   https://proceedings.mlr.press/v267/zhu25y.html
   Role: possible later external-control project, not implemented here.

The current trial design and data generator are illustrative choices, not clinical
parameters extracted from these publications.
