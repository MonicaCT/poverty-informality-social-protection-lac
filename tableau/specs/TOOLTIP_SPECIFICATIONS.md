# Tooltip Specifications

Every tooltip should include:

- country;
- year or selected period;
- indicator value and unit;
- source/comparability note where relevant;
- missingness warning when applicable;
- statement that the view is descriptive, not causal.

## Examples

Poverty tooltip:
`<Country>, <Year>: poverty rate <value>. Source definitions vary; interpret as descriptive harmonized indicator.`

Informality tooltip:
`<Country>, <Year>: labor informality <value>. ILOSTAT/fallback definitions may differ by coverage.`

Social protection tooltip:
`<Country>, <Year>: coverage <value>. Missing values indicate unavailable public source coverage, not zero coverage.`

Data quality tooltip:
`<Variable>: missingness <value>. High missingness constrains cross-country comparison.`
