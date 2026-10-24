# Project plan — version 0.1

## Purpose

Demonstrate clinical-trial statistical thinking through an end-to-end simulated
Phase II analysis, followed by CP and CRC modules. The first milestone is a
reproducible baseline, not a novel methodological paper. Phase I dose finding
and Phase III confirmatory multiplicity are outside the initial scope.

## Hypothetical trial

Adults with a hypothetical chronic condition receive investigational treatment
or standard care. Enroll 240 patients and use complete 1:1 randomization with
120 patients per arm. Follow each patient for 12 weeks. Higher improvement is
better. Primary endpoint: a continuous week-12 improvement score. Safety outcomes:
five binary adverse-event categories during the same follow-up window.
The endpoint scale is unbounded Gaussian in this initial simulation. It is not
a validated instrument, and the assumed three-point benefit is not an established
minimal clinically important difference. There is no efficacy-based enrollment,
adaptive randomization, interim analysis, or stopping rule in version 0.1.

## Primary analysis

Estimate the randomized-arm difference in mean improvement using ANCOVA adjusted
for baseline score, age, and biomarker. Present a two-sided 95% confidence interval
and a two-sided test at 0.05. No baseline significance testing. Summarize adverse
events descriptively without claiming causal risk reduction or formal safety.

## Simulation design

Version 0.1 uses constant additive effects of 0 and 3 points, residual SD 8,
correctly specified linear conditional means, independent patients, and complete
follow-up. Within-patient adverse-event dependence is induced through latent
susceptibility. Seeds and configuration are explicit.

Run 1,000 independent replicates per efficacy scenario. Estimate bias, RMSE,
confidence-interval coverage, Type I error, and power. Report Monte Carlo standard
errors; rejection rates additionally receive exact binomial Monte Carlo intervals.
The sample-size formula is a normal approximation using marginal outcome SD,
ignoring covariate-adjustment gains, with no dropout allowance. The fixed n=240
is a planned illustrative size, not selected after looking at simulation results.

Baseline, split CP, four-cell Mondrian CP and arm-specific CRC are implemented.
Author-supplied repeated simulation outputs were reviewed. See reports/results.md
and results/reference/ for findings and provenance. Real-data validation is deferred.

## Milestones and acceptance criteria

| Milestone | Deliverable | Acceptance criterion |
|---|---|---|
| 1: baseline trial | Simulator, SAP, tables, operating-characteristic driver | Tests execute; estimates and operating characteristics are reviewed with MC uncertainty |
| 2: CP | Arm-specific split conformal and model-based intervals | Finite-sample quantile rule tested; independent evaluation; report coverage and width |
| 3: CRC | Event probability models, nested sets, threshold calibration | Edge cases and fallback tested; independent evaluation of loss and burden |
| 4: robustness | Nonlinearity, small subgroups, missingness, shift | Separate assumptions-supported guarantees from empirical stress-test behavior |
| 5: portfolio | Rendered report and one suitable real-data demonstration | Clear status, reproducible commands, documented provenance and limitations |

## Scope control

Begin with logistic models for adverse events and a linear outcome model. Add
flexible models only after baseline calibration works. Do not implement treatment
recommendation or individual treatment-effect intervals in the first release.
Do not use hypothetical labels for counterfactual outcomes as observed calibration
data. Simulation truth may be used for evaluation only.

## Future realism

Add prespecified dropout mechanisms, continued follow-up after discontinuation,
severity grading, and clinically grounded distributions after selecting a disease.
Assess subgroups fixed before calibration, and demonstrate the limitations of
small group counts. Later trial-cohort reuse must not compromise train/calibration
independence. Selective external-control borrowing is a separate future project.
