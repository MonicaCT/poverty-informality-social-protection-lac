|metric                             |    value| p_value|interpretation                                                                                   |
|:----------------------------------|--------:|-------:|:------------------------------------------------------------------------------------------------|
|main_model_observations            | 178.0000|      NA|Complete preferred-model country-year observations.                                              |
|main_model_countries               |  17.0000|      NA|Country clusters; cluster-robust inference is finite-sample sensitive below roughly 30 clusters. |
|max_vif                            |   5.1202|      NA|Values above 10 indicate severe multicollinearity; values above 5 deserve scrutiny.              |
|breusch_pagan_heteroskedasticity   |  64.8251|  0.0000|Low p-value indicates heteroskedasticity; robust SE are therefore required.                      |
|panel_serial_correlation_pbgtest   |  28.9028|  0.0000|Low p-value indicates serial correlation in panel residuals.                                     |
|pesaran_cross_sectional_dependence |  -3.3271|  0.0009|Low p-value indicates cross-sectional dependence; interpret clustered SE cautiously.             |
|hausman_fe_vs_re                   |  12.2645|  0.0313|Low p-value favors fixed effects over random effects.                                            |
|twfe_residual_lag1_autocorrelation |   0.4593|      NA|Heuristic residual autocorrelation; formal panel test reported separately.                       |
