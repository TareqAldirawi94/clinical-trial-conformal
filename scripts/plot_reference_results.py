"""Regenerate repository figures from committed R summaries; no simulations run."""
from pathlib import Path
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports' / 'figures'
OUT.mkdir(parents=True, exist_ok=True)
plt.rcParams.update({'font.size': 11, 'axes.spines.top': False, 'axes.spines.right': False})
s = pd.read_csv(ROOT / 'results/reference/crc_summary.csv')
fig, axes = plt.subplots(1, 2, figsize=(11, 4.4))
for method, color in [('Empirical', '#b76b21'), ('CRC', '#167385')]:
 d = s[(s.group == 'Overall') & (s.method == method)].sort_values('n_cal_total')
 x = range(len(d))
 axes[0].errorbar(x, 100*d.risk, yerr=[100*(d.risk-d.risk_mc_lower),100*(d.risk_mc_upper-d.risk)], label=method, color=color, marker='o', capsize=4)
 axes[1].plot(x, d.mean_set_size, label=method, color=color, marker='o')
for ax in axes:
 ax.set_xticks(range(3), ['40', '100', '400']); ax.set_xlabel('Total calibration patients'); ax.grid(axis='y', alpha=.2)
axes[0].axhline(10, color='#444444', ls='--', label='10% target')
axes[0].set_ylabel('Mean missed-event risk (%)'); axes[0].set_ylim(0, 14); axes[0].legend(frameon=False)
axes[1].set_ylabel('Mean prediction-set size (of 5)'); axes[1].set_ylim(0, 5)
fig.suptitle('Adverse-event risk control: risk and prediction burden', fontsize=14)
fig.text(.5,.015,'200 replications per size. Error bars: 95% Monte Carlo intervals for mean risk.',ha='center',fontsize=9)
fig.tight_layout(rect=(0,.045,1,.94)); fig.savefig(OUT/'crc-comparison.png',dpi=180); plt.close(fig)
s = pd.read_csv(ROOT/'results/reference/mondrian_summary.csv')
s = s[(s.n_cal_total==400)&(s.scenario=='nonlinear_heteroscedastic')]
methods=list(s.method.unique()); colors=['#8a9096','#b76b21','#167385']
fig, ax=plt.subplots(figsize=(9,4.8))
for k,(method,color) in enumerate(zip(methods,colors)):
 d=s[s.method==method].set_index('group').loc[['Overall','Biomarker_nonpositive','Biomarker_positive']]
 x=[j+(k-1)*.18 for j in range(3)]
 ax.errorbar(x,100*d.mean_coverage,yerr=[100*(d.mean_coverage-d.coverage_mc_lower),100*(d.coverage_mc_upper-d.mean_coverage)],fmt='o',color=color,label=method,capsize=4)
ax.axhline(90,color='#444444',ls='--'); ax.set_xticks(range(3),['Overall','Biomarker ≤ 0','Biomarker > 0'])
ax.set_ylabel('Mean coverage (%)');ax.set_ylim(78,100);ax.grid(axis='y',alpha=.2)
ax.set_title('Outcome prediction: overall coverage can hide subgroup gaps')
ax.legend(loc='lower left',frameon=False)
fig.text(.5,.015,'Nonlinear, heteroscedastic scenario; n_cal=400; 200 replications. 95% Monte Carlo intervals.',ha='center',fontsize=9)
fig.tight_layout(rect=(0,.05,1,1));fig.savefig(OUT/'subgroup-coverage.png',dpi=180);plt.close(fig)
print('Reference figures regenerated.')
