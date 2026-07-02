# Empirical Strategy

## Decision Rule

The empirical strategy was selected after `DATA_INVENTORY.md` was completed. The data support an unbalanced LAC country-year panel rather than an immediately harmonized cross-country household microdata panel. The preferred estimation sample has 178 complete country-year rows, 17 country clusters, and years 2006-2023.

## Preferred Model

```text
Poverty_it = beta1 Informality_it + beta2 SocialProtection_it
           + beta3 Informality_it x SocialProtection_it
           + gamma Controls_it + alpha_i + tau_t + epsilon_it
```

The preferred model is two-way fixed effects with country and year effects. It uses country-clustered robust standard errors because heteroskedasticity, serial correlation, and cross-sectional dependence are detected in the diagnostics.

## Model Selection

- Fixed effects are preferred over random effects by the Hausman test (p=0.0313).
- Heteroskedasticity is present (Breusch-Pagan p=1.22e-12).
- Serial correlation is present (panel test p=7.61e-08).
- Cross-sectional dependence is present (Pesaran CD p=0.000878).
- Multicollinearity is moderate, not severe (max VIF=5.12).

## Model Suite

- Model 1: Pooled OLS with country-clustered robust standard errors.
- Model 2: Random effects with robust country clustering.
- Model 3: Country fixed effects.
- Model 4: Two-way fixed effects, the preferred baseline.
- Model 5: Hausman test.
- Model 6: Arellano-Bond dynamic panel, robustness only.
- Model 7: System GMM, robustness only.
- Model 8: Informality x social protection interaction.
- Model 9: Regional heterogeneity.
- Model 10: Lagged, alternative poverty, and alternative informality robustness checks.

## Interpretation Discipline

The results are associational. The strongest policy interpretation is that countries and years with broader social protection coverage tend to show lower poverty conditional on informality, macroeconomic conditions, inequality, and fixed effects. The interaction estimate is negative but imprecise, so it is a hypothesis-generating finding rather than causal proof.
