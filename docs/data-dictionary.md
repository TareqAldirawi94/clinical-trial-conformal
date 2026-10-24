# Synthetic data dictionary

One row per randomized patient; no real records or identifiers are used.

| Variable | Type / units | Definition |
|---|---|---|
| id | character | Synthetic identifier SIM0001, etc. |
| treatment | integer 0/1 | 0 control, 1 investigational; exactly balanced |
| age | years | Normal(55,12^2), clipped to [18,80] |
| baseline_score | arbitrary points | Normal(50,10^2); no bounded instrument assumed |
| biomarker | standardized arbitrary units | Standard normal |
| improvement_week12 | arbitrary points | Positive improvement is favorable |
| ae_nausea | binary | At least one nausea event during 12 weeks |
| ae_fatigue | binary | At least one fatigue event during 12 weeks |
| ae_rash | binary | At least one rash event during 12 weeks |
| ae_diarrhea | binary | At least one diarrhea event during 12 weeks |
| ae_headache | binary | At least one headache event during 12 weeks |

Efficacy generator:

    improvement = 4 + effect*treatment + 0.25*(baseline_score-50)
                  + 0.8*biomarker - 0.03*(age-55) + error

The independent error is Normal(0,residual_sd^2). The treatment coefficient is
the true population mean effect because allocation is randomized and the effect
is constant. The age clipping makes the planning variance calculation approximate.

Safety generator: independent Bernoulli draws conditional on treatment, biomarker,
and shared latent Normal(0,1) susceptibility. Log-odds for event j are
intercept_j + 0.35*treatment + 0.15*biomarker + 0.6*susceptibility. Intercepts are
(-1.8,-1.2,-2.4,-2.0,-1.6). Latent susceptibility is excluded from observed data.
The five labels are correlated marginally. These arbitrary parameters do not
represent a real drug's adverse-event profile. There is no event severity field.
