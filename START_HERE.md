# Start here

Repository: https://github.com/TareqAldirawi94/clinical-trial-conformal

## 1. Put the files in the project folder

Extract the ZIP and copy the contents of its `clinical-trial-conformal` folder
into your project folder. README.md, R/, scripts/ and .github/ must sit directly
at the repository root. Do not upload the ZIP itself or nest the whole project
inside another clinical-trial-conformal folder on GitHub.

Keep existing outputs/ locally. They are ignored by Git. Public scripts now use
the current project root, rather than silently switching to a personal path.
Open the .Rproj file or explicitly run in the RStudio Console:

```r
setwd("C:/Users/telde/Downloads/clinical-trial-conformal-starter/clinical-trial-conformal")
```

## 2. Run the checks

```r
source("tests/run_tests.R")
source("tests/test_conformal.R")
source("tests/test_mondrian.R")
source("tests/test_crc.R")
```

Retain any error and resolve it before describing the test suite as passing.
The baseline test also writes a single-trial output. Full-run commands are in
README.md; running them is not needed just to view the committed results report.

## 3. First upload to the empty repository

Use RStudio's Terminal tab or PowerShell, not the R Console. In PowerShell:

```powershell
cd "C:\Users\telde\Downloads\clinical-trial-conformal-starter\clinical-trial-conformal"
git init -b main
git add .
git status --short
git commit -m "Add clinical trial analysis, conformal prediction and risk control"
git remote add origin https://github.com/TareqAldirawi94/clinical-trial-conformal.git
git push -u origin main
```

Check that staged files include .github/workflows/r-checks.yml and the curated
results/reference/ files, but not generated outputs/ CSVs or R workspace files.
Authenticate through the browser or Git Credential Manager when prompted.
If Git requests an author identity, configure your own name and email locally:

```powershell
git config user.name "Tareq Aldirawi"
git config user.email "YOUR_VERIFIED_GITHUB_EMAIL_OR_NOREPLY_EMAIL"
```

Replace the email placeholder, then rerun the commit and push commands.
Do not force-push if the remote has acquired commits. Clone it into a new folder,
copy these project files into the clone, and make a normal commit instead.

GitHub Desktop is an alternative: add the extracted folder as a local repository,
review the changes, commit them, and set the remote to the URL above. Avoid browser
upload if it causes hidden .github/ or .gitignore files to be omitted.

## 4. Review on GitHub

Check README images and the reports/results.md link. Open Actions and review the
R checks workflow. A smoke simulation checks execution, not scientific performance.
Set the repository description to:

> R simulation study of Phase II trial analysis, conformal prediction, and adverse-event conformal risk control.

Suggested topics: r, biostatistics, clinical-trials, conformal-prediction,
conformal-risk-control, simulation, uncertainty-quantification.

No license is selected automatically. Add one deliberately before promising
others reuse rights.

## 5. Optional reports and figure regeneration

The committed reports/results.md renders directly on GitHub. Optional Quarto
reports require Quarto and knitr; render reports/analysis.qmd or reports/conformal.qmd
only after reviewing their input requirements. No LaTeX draft is needed to publish
the repository.

The committed PNG figures can be regenerated from reference CSVs with
`python scripts/plot_reference_results.py` using Python, pandas and matplotlib.
This optional figure tool is separate from the base-R analysis pipeline.
