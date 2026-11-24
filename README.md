# IDUtils

Utilities for working with persistent identifiers used in scholarly communication.


## Features

Match and normalize identifiers:

```elixir
iex> IDUtils.matches_scheme?("000000029079593X", :orcid)
true

iex> IDUtils.normalize("000000029079593X", :orcid)
{:ok, "0000-0002-9079-593X"}
```

Detect common persistent identifier schemes:

```elixir
iex> IDUtils.detect_schemes("0000000218250097")
[:orcid, :isni]

iex> IDUtils.detect_schemes("urn:doi:10.1093/annonc/mdz260.023")
[:doi, :handle, :urn]
```

Create links for resolvable identifiers:

```elixir
iex> IDUtils.to_url("0000000121480099", :isni)
{:ok, "https://isni.org/isni/0000000121480099"}

iex> IDUtils.to_uri("10.5281/zenodo.15293455", :doi)
{:ok, %URI{scheme: "https", host: "doi.org", path: "/10.5281/zenodo.15293455", port: 443}}
```

Supported Schemes: ARK, DOI, GND, Handle, ISNI, ISSN, OpenAlex ID, ORCID, RAID, ROR, URL, URN, 
VIAF.

Extendable: Implement the `IDUtils.Scheme` behaviour for your custom schemes.


## 🚧 Status

IDUtils is in 0.x. The library is functional and covered by tests, but the API may change between 
minor versions. Pin an exact version in your `deps` if you need stability across upgrades.


## Installation

Add `id_utils` to your dependencies in `mix.exs` (requires Elixir v1.18+):

```elixir
def deps do
  [
    {:id_utils, "~> 0.1"}
  ]
end
```

IDUtils is dependency-free and does not require any additional libraries.


## Documentation

The project documentation is [available via HexDocs](https://id-utils.hexdocs.pm).

To generate it locally, run:

```bash
mix docs
```

You can then open `doc/index.html` in your browser.


## Contributing

Feedback, bug reports, feature requests, and other contributions are most welcome. Please open an
[Issue](https://github.com/moefuerst/id_utils/issues) first if your change is larger in scope.
See `CONTRIBUTING.md` for more information.


## Acknowledgments

IDUtils is inspired by [inveniosoftware/idutils](https://github.com/inveniosoftware/idutils) and
is informed by its design and behavior (results differ from the Python library in places). Part of
the test data is derived from that project's test suite (see `NOTICE`). IDUtils is an independent
project and is not affiliated with or endorsed by CERN or Invenio.


## License

Copyright (C) 2026 Moritz F. Fürst

IDUtils is free software; you can redistribute it and/or modify it under the terms of the 
Revised BSD License, see `LICENSE`.
