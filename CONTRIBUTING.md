# Contributing

Feedback, bug reports, feature requests, and other contributions are most welcome. 

- To contribute updates, fixes or new features please fork and open a pull-request against `main.
- Please open an [Issue](https://github.com/moefuerst/id_utils/issues) first if your change is 
  larger in scope.
- Please use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/), this allows 
  us to dynamically generate the changelog.
- Please run `mix precommit` before committing your changes and `mix check` before pushing a 
  branch.


## Development

You can develop IDUtils on your local machine directly or using the provided dev container.

### Using Local Elixir/Erlang

Make sure Elixir and Erlang are available on your development machine. The required local tool 
versions are listed in `mise.toml` for use with [mise-en-place](https://mise.jdx.dev/) or similar
tools.

1. Navigate to the project directory and install the required Elixir and Erlang versions
   (if using `mise`):
   ```bash
   mise install
   ```
2. Fetch dependencies:
   ```bash
   mix deps.get
   ```
3. Compile the project:
   ```bash
   mix compile
   ```
4. Start the project in interactive mode (dev env):
   ```bash
   iex -S mix
   ```

### Using Docker

1. Fetch and install dependencies:
   ```bash
   make deps
   ```
2. Start a local development container:
   ```bash
   make dev
   ```

This will drop you into an interactive bash shell inside an ephemeral application container. From
there, you can start an IEx shell and run the project in interactive mode with `iex -S mix`.

Your local working directory is mounted inside the container for development using the editing
tools on your development machine. Dependencies and build artifacts are cached in named Docker 
volumes and persist across sessions.

To show all available targets, run

```bash
make help
```

Alternatively, a `devcontainer.json` spec file is provided for use with tools supporting 
[dev containers](https://containers.dev).


## Tests

```bash
mix test
```


## Code quality checks

The codebase is set up to perform quality checks using `credo`, `dialyzer` and the `styler` format
plugin. It's usually faster to not bother with individual checks and use one of the following 
aliases to run all of them.

To format your code, run all static analysis tools, and run the test suite, use:

```bash
mix precommit
```

For the checks that are performed by CI, use:

```bash
mix check
```
