# Changelog

## 0.6.0 - 2026-07-24

- Feat: Add `Connection#job_proposals` to list Vermittlungsvorschlag zip files from the BA `VV/` directory
- Feat: New `BaUpload::JobProposalFile` wrapper (binary-safe read/tempfile) analogous to `ErrorFile`

## 0.5.0 - 2024-10-14

- Feat: Support downloading Statistic xlsx files via `Connection#statistics` and new `BaUpload::StatisticFile` wrapper
- Fix: Backport OpenSSL legacy provider handling to older OpenSSL versions
- Chore: Bundler update

## 0.4.0 - 2023-09-26

- Feat: Support OpenSSL 3 legacy import (fixes `OpenSSL::PKCS12` "unsupported" error when loading legacy PKCS12 certificates)
- Doc: Add guide for generating a BA Feed and minor README fixes

## 0.3.0 - 2022-09-08

- Feat: Support multiple client certificates on a single `Connection` (thanks @UliKuch, #4)

## 0.2.0 - 2021-02-03

- Feat: Easily download misc "Sonstige" files via `Connection#misc`

## 0.1.0 - 2018-01-04

- Initial release extracted from Empfehlungsbund
- Fix: Also handle error files produced by company accounts
