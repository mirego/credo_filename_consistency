defmodule CredoNaming.Check.Consistency.ModuleFilename do
  use Credo.Check,
    base_priority: :low,
    tags: [:naming],
    explanations: [
      check: """
      If a file contains a single module, its filename should match the name of the module.

          # preferred

          # lib/foo/bar.exs
          defmodule Foo.Bar, do: nil

          # lib/foo/bar/bar.exs
          defmodule Foo.Bar, do: nil

          # lib/foo/foo.exs
          defmodule Foo, do: nil

          # lib/foo.exs
          defmodule Foo, do: nil

          # lib/foo/exceptions.exs
          defmodule Foo.FirstException, do: nil
          defmodule Foo.SecondException, do: nil

          # NOT preferred

          # lib/foo.exs
          defmodule Bar, do: nil

          # lib/foo/schemas/bar.exs
          defmodule Foo.Bar, do: nil
      """,
      params: [
        excluded_paths: "A list of paths to exclude",
        acronyms: "A list of tuples that map a module term to its path version, eg. [{\"MyAppGraphQL\", \"myapp_graphql\"}]",
        valid_filename_callback: "A function (either `&fun/3` or `{module, fun}`) that will be called on each filename with the name of the module it defines"
      ]
    ],
    param_defaults: [excluded_paths: [], acronyms: [], valid_filename_callback: {__MODULE__, :valid_filename?}]

  alias Credo.Code

  @doc false
  def run(source_file, params \\ []) do
    excluded_paths = Params.get(params, :excluded_paths, __MODULE__)
    issue_meta = IssueMeta.for(source_file, params)

    source_file.filename
    |> String.starts_with?(excluded_paths)
    |> Kernel.||(source_file.filename === "stdin")
    |> if do
      []
    else
      source_file
      |> Credo.SourceFile.ast()
      |> root_modules()
      |> issues(issue_meta, source_file, params)
    end
  end

  @doc "Returns whether the filename matches the module defined in it."
  def valid_filename?(filename, module_name, params) do
    expected_filenames = valid_filenames(filename, module_name, params)

    {filename in expected_filenames, expected_filenames}
  end

  @doc "Returns the root path of a file, with support for umbrella projects"
  def root_path(filename) do
    case Path.split(filename) do
      ["apps", app, root | _] -> Path.join(["apps", app, root])
      [root | _] -> root
    end
  end

  defp issues([{module_name, line_no}], issue_meta, source_file, params) do
    params
    |> Params.get(:valid_filename_callback, __MODULE__)
    |> case do
      {mod, fun} ->
        apply(mod, fun, [source_file.filename, module_name, params])

      fun ->
        fun.(source_file.filename, module_name, params)
    end
    |> case do
      {true, _} ->
        []

      {false, expected_filenames} ->
        [issue_for(issue_meta, line_no, source_file, expected_filenames, module_name)]
    end
  end

  defp issues(_, _, _, _), do: []

  defp root_modules({:__block__, _, statements}) do
    Enum.flat_map(statements, &root_modules/1)
  end

  defp root_modules({:defmodule, opts, _} = module) do
    name = Code.Module.name(module)
    line_no = Keyword.get(opts, :line)

    [{name, line_no}]
  end

  defp root_modules({:defprotocol, opts, args}) do
    # Credo.Code.Module doesn't understand defprotocol, work around it
    root_modules({:defmodule, opts, args})
  end

  defp root_modules(_), do: []

  defp issue_for(issue_meta, line_no, %{filename: filename}, expected_filenames, full_name) do
    format_issue(
      issue_meta,
      message: """
      The module defined in `#{filename}` is not named consistently with the filename. The file should be named either:
      #{inspect(expected_filenames)}
      """,
      trigger: full_name,
      line_no: line_no
    )
  end

  defp valid_filenames(filename, module_name, params) do
    acronyms = Params.get(params, :acronyms, __MODULE__)
    extension = Path.extname(filename)
    root_path = root_path(filename)

    module_part_list = module_name |> replace_acronyms(acronyms) |> String.split(".") |> Enum.map(&Macro.underscore/1)

    # phoenix specific call that appends "controller" or "view" to the path
    module_part_list = maybe_insert_web_resource(module_part_list, "controller")
    module_part_list = maybe_insert_web_resource(module_part_list, "view")

    valid_module_path_name = Enum.join(module_part_list, "/")

    [Path.join([root_path, valid_module_path_name <> extension])]
  end

  defp maybe_insert_web_resource(module_part_list, resource_type) do
    path = Enum.at(module_part_list, 0)
    file_name = Enum.at(module_part_list, -1)

    # we want to append the "resource_type" to the second path position
    # if file ends with the resource type.
    # So, in phoenix, will have: "/lib/app/controllers/my_controller" and the module as App.MyController.
    # This module will put the pluralized "resource_type" at second position on the path
    # generated from module's name
    if String.ends_with?(path, "_web") and (String.ends_with?(file_name, "_#{resource_type}") or String.ends_with?(file_name, "_#{resource_type}_test")) do
      List.insert_at(module_part_list, 1, resource_type <> "s")
    else
      module_part_list
    end
  end

  defp replace_acronyms(module, acronyms) do
    Enum.reduce(acronyms, module, &process_acronym/2)
  end

  defp process_acronym(string, acc) when is_binary(string) do
    downcase_string = String.downcase(string)
    String.replace(acc, string, downcase_string)
  end

  defp process_acronym({string, processed_string}, acc) do
    downcase_string = String.downcase(processed_string)
    String.replace(acc, string, downcase_string)
  end

  defp process_acronym(_, acc), do: acc
end
