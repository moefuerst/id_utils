defmodule IDUtils.FixtureCase do
  @moduledoc """
  Defines the setup for tests requiring static fixture data.

  Modules using this case set `@fixtures` to a map of fixture names to paths relative to
  `test/support/fixtures`:

      @fixtures %{
        my_fixture: ["folder", "fixture.jsonc"]
      }

  This will expose a `my_fixture/0` function that returns the parsed fixture data.

  Test data is a JSONC file: standard JSON containing an array of objects, with optional *leading*
  `//` comment lines.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      @before_compile IDUtils.FixtureCase
    end
  end

  defmacro __before_compile__(env) do
    data = Module.get_attribute(env.module, :fixtures)

    if not is_map(data) do
      raise CompileError, file: env.file, description: "#{env.module} must set @fixtures to a map"
    end

    for {name, path} <- data do
      fixtures = load_fixture!(path)

      if fixtures == [] or not is_list(fixtures) do
        raise CompileError, file: env.file, description: "fixture #{inspect(path)} must not be empty"
      end

      Module.put_attribute(env.module, name, fixtures)

      quote do
        @external_resource unquote(Path.join(["test", "support", "fixtures"] ++ List.wrap(path)))
        def unquote(name)(), do: unquote(Macro.escape(fixtures))
      end
    end
  end

  @doc """
  Loads a JSONC fixture.

  Leading `//` comment lines are ignored.
  """
  def load_fixture!(path) do
    (["test", "support", "fixtures"] ++ List.wrap(path))
    |> Path.join()
    |> File.stream!()
    |> Stream.drop_while(&String.starts_with?(&1, "//"))
    |> Enum.join()
    |> JSON.decode!()
  end
end
