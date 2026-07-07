# Contributing

Thank you for considering a contribution. This repository is maintained as a professional research portfolio project, so contributions should improve scientific credibility, reproducibility, documentation, or publication quality.

## Good Contributions

- Improve data provenance, codebooks, or validation checks.
- Add defensible robustness checks or diagnostics.
- Improve figure clarity without changing the underlying results silently.
- Fix reproducibility issues on a clean machine.
- Improve documentation, examples, or GitHub Pages content.

## Reproducibility Requirements

Before opening a pull request, run:

```bash
python code/python/02_descriptive_analysis.py
python code/python/03_build_dashboard.py
python tests/test_panel_integrity.py
python tests/test_repository_outputs.py
python tests/test_publication_readiness.py
```

If your change requires raw data, explain which source is needed and why the public processed-panel workflow cannot test it.

## Research Standards

- Do not introduce causal language unless the identification strategy supports it.
- Report standard-error assumptions clearly.
- Document any sample restriction, dropped variable, or model replacement.
- Keep generated outputs reproducible from code.
- Do not commit private raw data or credentials.

## Pull Request Expectations

A strong pull request includes a concise motivation, a list of changed files, the commands run, and any remaining limitations.

