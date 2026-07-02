|model                                          |term                                                   | estimate| std.error| statistic| p.value| conf.low| conf.high|se_type                        |
|:----------------------------------------------|:------------------------------------------------------|--------:|---------:|---------:|-------:|--------:|---------:|:------------------------------|
|Model 1 - Pooled OLS                           |(Intercept)                                            |  97.1150|   51.1507|    1.8986|  0.0593|  -3.1404|  197.3704|HC1 country-clustered          |
|Model 1 - Pooled OLS                           |labor_informality                                      |   0.2412|    0.1640|    1.4703|  0.1433|  -0.0803|    0.5626|HC1 country-clustered          |
|Model 1 - Pooled OLS                           |social_protection_coverage                             |  -0.2167|    0.1025|   -2.1129|  0.0361|  -0.4176|   -0.0157|HC1 country-clustered          |
|Model 1 - Pooled OLS                           |log_gdp_per_capita                                     | -10.4490|    5.6513|   -1.8489|  0.0662| -21.5256|    0.6277|HC1 country-clustered          |
|Model 1 - Pooled OLS                           |gini                                                   |   0.5023|    0.3704|    1.3561|  0.1768|  -0.2236|    1.2282|HC1 country-clustered          |
|Model 1 - Pooled OLS                           |unemployment                                           |   0.1588|    0.4010|    0.3961|  0.6925|  -0.6271|    0.9448|HC1 country-clustered          |
|Model 2 - Random Effects                       |(Intercept)                                            | 221.1129|   36.6025|    6.0409|  0.0000| 149.3720|  292.8539|Arellano HC1 country-clustered |
|Model 2 - Random Effects                       |labor_informality                                      |   0.0759|    0.0695|    1.0918|  0.2764|  -0.0603|    0.2121|Arellano HC1 country-clustered |
|Model 2 - Random Effects                       |social_protection_coverage                             |  -0.0834|    0.0338|   -2.4691|  0.0145|  -0.1496|   -0.0172|Arellano HC1 country-clustered |
|Model 2 - Random Effects                       |log_gdp_per_capita                                     | -25.9623|    3.6263|   -7.1594|  0.0000| -33.0699|  -18.8547|Arellano HC1 country-clustered |
|Model 2 - Random Effects                       |gini                                                   |   0.7989|    0.1891|    4.2256|  0.0000|   0.4283|    1.1695|Arellano HC1 country-clustered |
|Model 2 - Random Effects                       |unemployment                                           |   0.4312|    0.1837|    2.3469|  0.0201|   0.0711|    0.7913|Arellano HC1 country-clustered |
|Model 3 - Country Fixed Effects                |labor_informality                                      |   0.0940|    0.0727|    1.2931|  0.1979|  -0.0485|    0.2364|Arellano HC1 country-clustered |
|Model 3 - Country Fixed Effects                |social_protection_coverage                             |  -0.0745|    0.0314|   -2.3738|  0.0188|  -0.1361|   -0.0130|Arellano HC1 country-clustered |
|Model 3 - Country Fixed Effects                |log_gdp_per_capita                                     | -30.3565|    5.1080|   -5.9429|  0.0000| -40.3682|  -20.3448|Arellano HC1 country-clustered |
|Model 3 - Country Fixed Effects                |gini                                                   |   0.6897|    0.2408|    2.8637|  0.0048|   0.2176|    1.1617|Arellano HC1 country-clustered |
|Model 3 - Country Fixed Effects                |unemployment                                           |   0.4279|    0.2019|    2.1188|  0.0357|   0.0321|    0.8236|Arellano HC1 country-clustered |
|Model 4 - Two-way Fixed Effects                |labor_informality                                      |   0.0888|    0.0735|    1.2081|  0.2291|  -0.0553|    0.2329|Arellano HC1 country-clustered |
|Model 4 - Two-way Fixed Effects                |social_protection_coverage                             |  -0.1024|    0.0365|   -2.8077|  0.0057|  -0.1738|   -0.0309|Arellano HC1 country-clustered |
|Model 4 - Two-way Fixed Effects                |log_gdp_per_capita                                     | -25.9682|    7.8995|   -3.2873|  0.0013| -41.4513|  -10.4852|Arellano HC1 country-clustered |
|Model 4 - Two-way Fixed Effects                |gini                                                   |   0.5083|    0.1755|    2.8962|  0.0044|   0.1643|    0.8524|Arellano HC1 country-clustered |
|Model 4 - Two-way Fixed Effects                |unemployment                                           |   0.8935|    0.2528|    3.5341|  0.0006|   0.3980|    1.3890|Arellano HC1 country-clustered |
|Model 6 - Arellano-Bond Dynamic Panel          |lag(monetary_poverty, 1)                               |  -0.0445|    0.1509|   -0.2950|  0.7680|  -0.3402|    0.2512|robust GMM vcovHC              |
|Model 6 - Arellano-Bond Dynamic Panel          |labor_informality                                      |  -0.0050|    0.2195|   -0.0229|  0.9817|  -0.4353|    0.4252|robust GMM vcovHC              |
|Model 6 - Arellano-Bond Dynamic Panel          |social_protection_coverage                             |  -0.0143|    0.0721|   -0.1977|  0.8433|  -0.1556|    0.1271|robust GMM vcovHC              |
|Model 6 - Arellano-Bond Dynamic Panel          |log_gdp_per_capita                                     | -35.1786|   10.5763|   -3.3262|  0.0009| -55.9081|  -14.4491|robust GMM vcovHC              |
|Model 6 - Arellano-Bond Dynamic Panel          |gini                                                   |   0.7788|    0.5415|    1.4382|  0.1504|  -0.2826|    1.8402|robust GMM vcovHC              |
|Model 7 - System GMM                           |lag(monetary_poverty, 1)                               |   0.6877|    0.1304|    5.2723|  0.0000|   0.4320|    0.9433|robust GMM vcovHC              |
|Model 7 - System GMM                           |labor_informality                                      |   0.0491|    0.0794|    0.6185|  0.5363|  -0.1065|    0.2048|robust GMM vcovHC              |
|Model 7 - System GMM                           |social_protection_coverage                             |   0.0285|       NaN|       NaN|     NaN|       NA|        NA|robust GMM vcovHC              |
|Model 7 - System GMM                           |log_gdp_per_capita                                     |  -3.4090|    0.9622|   -3.5428|  0.0004|  -5.2950|   -1.5230|robust GMM vcovHC              |
|Model 7 - System GMM                           |gini                                                   |   0.7205|    0.2655|    2.7138|  0.0067|   0.2001|    1.2408|robust GMM vcovHC              |
|Model 8 - Informality x Social Protection      |labor_informality                                      |   0.2183|    0.1251|    1.7458|  0.1013|  -0.0268|    0.4635|country-clustered              |
|Model 8 - Informality x Social Protection      |social_protection_coverage                             |   0.0230|    0.1026|    0.2238|  0.8260|  -0.1782|    0.2241|country-clustered              |
|Model 8 - Informality x Social Protection      |log_gdp_per_capita                                     | -25.3746|    8.5533|   -2.9666|  0.0096| -42.1390|   -8.6101|country-clustered              |
|Model 8 - Informality x Social Protection      |gini                                                   |   0.4961|    0.1912|    2.5952|  0.0203|   0.1214|    0.8708|country-clustered              |
|Model 8 - Informality x Social Protection      |unemployment                                           |   0.8687|    0.2581|    3.3653|  0.0043|   0.3628|    1.3747|country-clustered              |
|Model 8 - Informality x Social Protection      |labor_informality:social_protection_coverage           |  -0.0019|    0.0015|   -1.2471|  0.2315|  -0.0049|    0.0011|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Caribbean:labor_informality                |  -0.2898|    0.2386|   -1.2145|  0.2433|  -0.7574|    0.1779|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Central America:labor_informality          |   0.1983|    0.3833|    0.5174|  0.6124|  -0.5530|    0.9496|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Mercosur:labor_informality                 |   0.0445|    0.1779|    0.2499|  0.8060|  -0.3043|    0.3932|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Mexico:labor_informality                   |   1.7780|    0.5992|    2.9674|  0.0096|   0.6036|    2.9524|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Southern Cone:labor_informality            |   0.3007|    0.0726|    4.1418|  0.0009|   0.1584|    0.4430|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Caribbean:social_protection_coverage       |  -0.1384|    0.0488|   -2.8335|  0.0126|  -0.2341|   -0.0427|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Central America:social_protection_coverage |  -0.0892|    0.0805|   -1.1081|  0.2853|  -0.2470|    0.0686|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Mercosur:social_protection_coverage        |  -0.1750|    0.0817|   -2.1430|  0.0489|  -0.3350|   -0.0149|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Mexico:social_protection_coverage          |  -0.1963|    0.0835|   -2.3498|  0.0329|  -0.3600|   -0.0326|country-clustered              |
|Model 9 - Regional Heterogeneity               |region_lac::Southern Cone:social_protection_coverage   |  -0.3903|    0.1465|   -2.6646|  0.0177|  -0.6774|   -0.1032|country-clustered              |
|Model 9 - Regional Heterogeneity               |log_gdp_per_capita                                     | -31.4249|    8.6364|   -3.6386|  0.0024| -48.3524|  -14.4975|country-clustered              |
|Model 9 - Regional Heterogeneity               |gini                                                   |   0.6774|    0.2342|    2.8925|  0.0112|   0.2184|    1.1364|country-clustered              |
|Model 9 - Regional Heterogeneity               |unemployment                                           |   0.5897|    0.2922|    2.0184|  0.0618|   0.0171|    1.1624|country-clustered              |
|Model 10a - Lagged Variables Robustness        |labor_informality_lag1                                 |   0.0827|    0.0711|    1.1631|  0.2642|  -0.0567|    0.2221|country-clustered              |
|Model 10a - Lagged Variables Robustness        |social_protection_lag1                                 |  -0.1089|    0.0547|   -1.9912|  0.0663|  -0.2160|   -0.0017|country-clustered              |
|Model 10a - Lagged Variables Robustness        |log_gdp_per_capita                                     | -37.8640|   12.2429|   -3.0927|  0.0079| -61.8601|  -13.8680|country-clustered              |
|Model 10a - Lagged Variables Robustness        |gini                                                   |  -0.3317|    0.7886|   -0.4206|  0.6804|  -1.8774|    1.2140|country-clustered              |
|Model 10a - Lagged Variables Robustness        |unemployment                                           |   1.3177|    0.6989|    1.8854|  0.0803|  -0.0521|    2.6875|country-clustered              |
|Model 10b - Extreme Poverty Robustness         |labor_informality                                      |  -0.0009|    0.0418|   -0.0208|  0.9837|  -0.0828|    0.0811|country-clustered              |
|Model 10b - Extreme Poverty Robustness         |social_protection_coverage                             |  -0.0499|    0.0146|   -3.4160|  0.0038|  -0.0786|   -0.0213|country-clustered              |
|Model 10b - Extreme Poverty Robustness         |log_gdp_per_capita                                     |  -4.5597|    2.9427|   -1.5495|  0.1421| -10.3275|    1.2080|country-clustered              |
|Model 10b - Extreme Poverty Robustness         |gini                                                   |   0.3332|    0.0782|    4.2619|  0.0007|   0.1800|    0.4864|country-clustered              |
|Model 10b - Extreme Poverty Robustness         |unemployment                                           |   0.2491|    0.0931|    2.6764|  0.0173|   0.0667|    0.4315|country-clustered              |
|Model 10c - Alternative Informality Robustness |informality_social_protection_equity                   |   0.1576|    0.1581|    0.9970|  0.3423|  -0.1522|    0.4674|country-clustered              |
|Model 10c - Alternative Informality Robustness |social_protection_coverage                             |  -0.0904|    0.0578|   -1.5633|  0.1490|  -0.2038|    0.0229|country-clustered              |
|Model 10c - Alternative Informality Robustness |log_gdp_per_capita                                     | -20.1166|   22.5798|   -0.8909|  0.3939| -64.3731|   24.1398|country-clustered              |
|Model 10c - Alternative Informality Robustness |gini                                                   |   0.4033|    0.3037|    1.3278|  0.2137|  -0.1920|    0.9985|country-clustered              |
|Model 10c - Alternative Informality Robustness |unemployment                                           |   0.6698|    0.3617|    1.8517|  0.0938|  -0.0392|    1.3788|country-clustered              |
