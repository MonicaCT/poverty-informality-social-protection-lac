# GMM Diagnostic Output

## Arellano-Bond Dynamic Panel
Oneway (individual) effect Two-steps model Difference GMM 

Call:
pgmm(formula = monetary_poverty ~ lag(monetary_poverty, 1) + 
    labor_informality + social_protection_coverage + log_gdp_per_capita + 
    gini | lag(monetary_poverty, 2:3), data = pdata, effect = "individual", 
    model = "twosteps", transformation = "d")

Unbalanced Panel: n = 17, T = 1-15, N = 178

Number of Observations Used: 108
Residuals:
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
-4.94208  0.00000  0.00000  0.01504  0.00000  8.42016 

Coefficients:
                             Estimate Std. Error z-value  Pr(>|z|)    
lag(monetary_poverty, 1)    -0.044504   0.150856 -0.2950 0.7679864    
labor_informality           -0.005033   0.219514 -0.0229 0.9817076    
social_protection_coverage  -0.014252   0.072094 -0.1977 0.8432885    
log_gdp_per_capita         -35.178626  10.576277 -3.3262 0.0008804 ***
gini                         0.778840   0.541530  1.4382 0.1503713    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Sargan test: chisq(30) = 8.263382 (p-value = 0.99997)
Autocorrelation test (1): normal = -0.7046344 (p-value = 0.48104)
Autocorrelation test (2): normal = -0.05576113 (p-value = 0.95553)
Wald test for coefficients: chisq(5) = 46.47157 (p-value = 7.2803e-09)

## System GMM
Oneway (individual) effect Two-steps model System GMM 

Call:
pgmm(formula = monetary_poverty ~ lag(monetary_poverty, 1) + 
    labor_informality + social_protection_coverage + log_gdp_per_capita + 
    gini | lag(monetary_poverty, 2:3), data = pdata, effect = "individual", 
    model = "twosteps", transformation = "ld")

Unbalanced Panel: n = 17, T = 1-15, N = 178

Number of Observations Used: 239
Residuals:
    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
-15.7886   0.0000   0.0000   0.1106   0.0000  17.3469 

Coefficients:
                            Estimate Std. Error z-value  Pr(>|z|)    
lag(monetary_poverty, 1)    0.687687   0.130434  5.2723 1.347e-07 ***
labor_informality           0.049123   0.079423  0.6185 0.5362532    
social_protection_coverage  0.028518        NaN     NaN       NaN    
log_gdp_per_capita         -3.409026   0.962233 -3.5428 0.0003959 ***
gini                        0.720470   0.265480  2.7138 0.0066509 ** 
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Sargan test: chisq(50) = 7.055701 (p-value = 1)
Autocorrelation test (1): normal = -2.466517 (p-value = 0.013643)
Autocorrelation test (2): normal = 1.928751 (p-value = 0.053762)
Wald test for coefficients: chisq(5) = 13977.76 (p-value = < 2.22e-16)

Interpretation note: singular first- or second-step weighting matrices signal weak finite-sample reliability and possible instrument problems. These models are robustness checks, not headline estimates.
