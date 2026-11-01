defmodule IDUtils.Scheme.CatalogTest do
  use ExUnit.Case, async: true

  alias IDUtils.Scheme.Catalog

  describe "all/0" do
    test "returns a catalog that has unique keys" do
      keys = Keyword.keys(Catalog.all())

      assert keys == Enum.uniq(keys)
    end

    test "maps each module to exactly one key" do
      modules = Enum.map(Catalog.all(), fn {_key, module} -> module end)

      assert modules == Enum.uniq(modules)
    end
  end

  test "module_for/1 resolves every registered key" do
    for {key, module} <- Catalog.all() do
      assert Catalog.module_for(key) == {:ok, module}
    end
  end

  test "name_for/1 resolves every registered module" do
    for {key, module} <- Catalog.all() do
      assert Catalog.name_for(module) == {:ok, key}
    end
  end

  test "extend/1 raises when a custom scheme key already exists, reports all conflicting keys" do
    [{first, _}, {second, _} | _] = Catalog.all()
    custom_with_existing_keys = [{first, MyApp.A}, {second, MyApp.B}]

    error =
      assert_raise ArgumentError, fn ->
        Catalog.extend(custom_with_existing_keys)
      end

    assert error.message =~ inspect(first)
    assert error.message =~ inspect(second)
  end

  test "custom schemes are resolvable alongside built-ins" do
    extended = Catalog.extend(my_scheme: MyApp.CustomScheme)

    assert Catalog.module_for(:my_scheme, extended) == {:ok, MyApp.CustomScheme}
    assert Catalog.name_for(MyApp.CustomScheme, extended) == {:ok, :my_scheme}

    for {key, module} <- Catalog.all() do
      assert Catalog.module_for(key, extended) == {:ok, module}
    end
  end
end
