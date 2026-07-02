# Final Publication Checklist

This checklist should be completed before making the repository public on GitHub.

## Repository Presentation

- [x] README rewritten for GitHub portfolio review.
- [x] Badges added.
- [x] Repository banner generated at `assets/brand/repository-banner.png`.
- [x] Social preview image generated at `assets/brand/social-preview.png`.
- [x] Dashboard screenshots generated under `assets/screenshots/`.
- [x] Every numbered figure appears in the README.
- [x] GitHub Pages documentation created under `docs/`.

## Community And Metadata

- [x] `LICENSE` generated.
- [x] `CITATION.cff` generated.
- [x] `CONTRIBUTING.md` generated.
- [x] `CHANGELOG.md` generated.
- [x] `CODE_OF_CONDUCT.md` generated.
- [x] `.gitignore` generated.
- [x] `.gitattributes` generated.
- [x] Issue templates created.
- [x] Pull request template created.
- [x] Releases folder created.

## Reproducibility

- [x] Public workflow runs from the included processed panel.
- [x] Optional raw rebuild remains available for private local archives.
- [x] GitHub Actions CI configured.
- [x] Publication-readiness test checks assets, links, templates, and temporary files.
- [x] No temporary files should remain before first commit.

## GitHub Settings To Complete After Creating The Remote

- [ ] Upload `assets/brand/social-preview.png` as the GitHub repository social preview image.
- [ ] Enable GitHub Pages using the `docs/` source or run the manual Pages workflow.
- [ ] Add repository topics: `development-economics`, `poverty`, `informality`, `social-protection`, `latin-america`, `reproducible-research`.
- [ ] Create the first release using `releases/v0.1.0/RELEASE_NOTES.md`.
- [ ] Confirm CI passes on GitHub before announcing the repository.

## Publication Gate

The repository should not be announced publicly until CI passes, the social preview is configured, and the first release notes have been reviewed.
