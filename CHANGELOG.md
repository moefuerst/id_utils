# CHANGELOG

All notable changes to this project will be documented in this file.

## [v0.1.0] – 2026-11-24

### Added

  * API entrypoint module `IDUtils`
  * Scheme modules `IDUtils.Schemes.ARK`, `IDUtils.Schemes.DOI`, `IDUtils.Schemes.GND`,
    `IDUtils.Schemes.Handle`, `IDUtils.Schemes.ISNI`, `IDUtils.Schemes.ISSN`,
    `IDUtils.Schemes.OpenAlex`, `IDUtils.Schemes.ORCID`, `IDUtils.Schemes.RAID`,
    `IDUtils.Schemes.ROR`, `IDUtils.Schemes.URL`, `IDUtils.Schemes.URN`, and
    `IDUtils.Schemes.VIAF`.
  * `IDUtils.Checksum` shared checksum algorithm module.
  * `IDUtils.Scheme.Catalog` and `IDUtils.Scheme.Disambiguation` modules for scheme detection 
    rules.
  * `IDUtils.Scheme` behaviour.

### Documentation

  * Basic documentation of all modules.

### Development

  * Added basic test coverage.
  * Added sampled test data.
  * Added `IDUtils.FixtureCase` test infrastructure.
  * Added container tooling.
  * Added CI setup.
  * Hex package setup.
  * Initialized project.


[v0.1.0]: https://github.com/moefuerst/id_utils/releases/tag/v0.1.0
