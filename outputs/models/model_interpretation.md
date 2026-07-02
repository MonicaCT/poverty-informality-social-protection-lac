# Model Interpretation

## Empirical Strategy Selected from the Inventory

The inventory supports an unbalanced LAC country-year panel with strong coverage for poverty, social protection, and macro controls, but a binding sample constraint for informality. The preferred estimand is therefore a two-way fixed-effects association between poverty, labor informality, social protection, and their interaction.

## Diagnostic Summary

Complete preferred-model observations: 178; country clusters: 17.
Maximum VIF: 5.12.
Hausman p-value: 0.03134.
Heteroskedasticity, serial correlation, and cross-sectional-dependence diagnostics are exported to econometric_diagnostics.csv and .md.

## Statistical Interpretation

Model 8 interaction estimate: -0.0019; p-value: 0.2315.
Model 8 informality main effect: 0.2183.
Model 8 social protection main effect: 0.023.

## Economic Interpretation

Positive informality coefficients indicate that higher labor informality is associated with higher monetary poverty after accounting for macro conditions, inequality, country fixed effects, and year shocks. Negative social-protection coefficients are consistent with protection systems mitigating poverty exposure, but the analysis remains associational.

## Policy Interpretation

The interaction coefficient asks whether social protection changes the slope linking informality to poverty. A negative coefficient is consistent with mitigation, but the current confidence interval is wide, so the result should motivate further microdata and policy-timing work rather than be treated as a causal estimate.

## Limitations

- The panel is unbalanced, especially for the joint informality-social protection sample.
- Social protection coverage is endogenous to poverty, politics, and fiscal capacity.
- Fewer than 30 country clusters makes clustered inference finite-sample sensitive.
- Dynamic GMM estimates produced singular weighting-matrix warnings and are robustness checks only.

## Future Research

- Use household microdata to validate national aggregates, especially Bolivia.
- Add program rollout timing for event-study or difference-in-differences designs.
- Harmonize survey weights and poverty-line definitions source by source.

