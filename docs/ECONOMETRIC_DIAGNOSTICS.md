# Econometric Diagnostics

## Why Diagnostics Matter

The initial model suite estimated successfully, but successful estimation is not sufficient for publication-quality evidence. The audited model layer now reports robust or country-clustered standard errors and exports formal diagnostics.

## Preferred Sample

- Complete preferred-model observations: 178
- Country clusters: 17
- Years: 2006-2023

## Diagnostic Results

| Diagnostic | Result | Interpretation |
|---|---:|---|
| Maximum VIF | 5.12 | Moderate multicollinearity, mainly informality and GDP. Not severe, but interpretation should emphasize signs and robustness. |
| Breusch-Pagan p-value | 1.22e-12 | Heteroskedasticity is present; robust standard errors are required. |
| Panel serial correlation p-value | 7.61e-08 | Serial correlation is present; country-clustered and panel-robust inference is required. |
| Pesaran CD p-value | 0.000878 | Cross-sectional dependence is present; results should be interpreted cautiously. |
| Hausman p-value | 0.0313 | Fixed effects are preferred over random effects. |

## Consequences for Interpretation

- The preferred model is two-way fixed effects with country-clustered robust standard errors.
- The informality coefficient remains positive but is not conventionally significant after robust clustering.
- Social protection coverage remains negatively associated with poverty.
- The interaction between informality and social protection is negative but imprecise.
- Dynamic GMM should not be used as the headline result due to singular weighting-matrix warnings.
