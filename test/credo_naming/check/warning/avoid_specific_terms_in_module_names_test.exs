defmodule CredoNaming.Check.Warning.AvoidSpecificTermsInModuleNamesTest do
  use Credo.TestHelper

  @described_check CredoNaming.Check.Warning.AvoidSpecificTermsInModuleNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation" do
    """
    defmodule App do
    end
    """
    |> to_source_file
    |> refute_issues(@described_check, terms: ["Manager"])
  end

  test "it should NOT report violation in a nested module" do
    """
    defmodule App do
      defmodule UserPersister do
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check, terms: ["Manager"])
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule App.FooManager do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, terms: ["Manager"])
  end

  test "it should report a violation in a nested module" do
    """
    defmodule App do
      defmodule Foo.Manager do
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, terms: ["Manager"])
  end

  test "it should report a violation in a parent module" do
    """
    defmodule App.Helpers.Error do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, terms: ["Helpers"])
  end

  test "it should report a violation in a module with mixed case" do
    """
    defmodule App.Helper.Error do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, terms: ["helper"])
  end

  test "it should report a violation in a module matching a regular expression" do
    """
    defmodule App.Helper.Error do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, terms: ["Manager", ~r/^helpers?$/i])
  end

  #
  # configuration raising errors
  #

  test "it should raise an error when a non-String or non-Regex is used as a term" do
    run_check = fn ->
      """
      defmodule App.Helper.Error do
      end
      """
      |> to_source_file
      |> assert_issue(@described_check, terms: ["Manager", ~r/^helpers?$/i, 42])
    end

    assert_raise RuntimeError, "The \"terms\" config expected each term to be a String or Regex, got: 42", run_check
  end
end
