# 1. Project configs
Every dbt project needs a "dbt_project.yml" file; this is how dbt knows a directory is a dbt project.

## .dbtignore
You can create a ".dbtignore" file, in the root of your dbt project, to specify files that should be entirely ignored by dbt. The file behaves like a ".gitignore" file, using the same syntax. 

Files and subdirectories matching the pattern will not be read/parsed/detected by dbt; as if they didn't exist.

## analysis-paths
`analysis-paths: ["my_folder_name"]`, lives in "dbt_project.yml" file. For saved sql queries, that do not materialize. 

`dbt init` cmd sets its default val to `analyses`. 

## asset-paths
`asset-paths: ["my_folder_name"]`, lives in "dbt_project.yml" file. For images in documentation. 

`dbt init` cmd doesn't set any value for this config. 

## clean-targets
`clean-targets: [my_folder_name1, my_folder_name2, ...]`, lives in "dbt_project.yml" file. A custom list of directories to be removed by the `dbt clean` command. 

`dbt init` cmd sets its default val to `target` and `dbt_packages`. 

## config-version
Starting in dbt v1.5, the `config-version` config is optional.

## seed-paths
`seed-paths: ["my_folder_name"]`, lives in "dbt_project.yml" file. Specifies seed files locations. 

`dbt init` cmd sets its default val to `seeds`. 

## dispatch (config)
By default, when `dispatch` search for macros, it will look in your root project first, and then look for implementations in the package named by `macro_namespace`.

## docs-paths
`docs-paths: ["my_folder_path"]`, lives in "dbt_project.yml" file. A custom list of directories, where docs blocks are located.

By default, dbt will search in all resource paths for docs blocks. If this option is configured, dbt will only look in the specified directory for docs blocks.

## log-path
Deprecated.

## macro-paths
By default, dbt will search for macros in a directory named `macros`. You can override it with `macro-paths: ["my_folder_path"]`. 

## packages-install-path
By default, dbt will install packages in the "dbt_packages" directory.

## name
The name of a dbt project.

## on-run-start & on-run-end
sql to run as hooks. Also take macros. 

## profile
The profile your dbt project should use to connect to your data warehouse. Not applicable to dbt Cloud. 

## query-comment
A string to inject as a comment, in each query, that dbt runs against your database. This comment can be used to attribute SQL statements to specific dbt resources, like models and tests. Can call a macro

By default, dbt will insert a JSON comment at the top of your query, containing the information including the dbt version, profile and target names, and node ids for the resources it runs. 

## quoting
On Snowflake, quoting is set to "false" by default. Creating relations with quoted identifiers makes those them case sensitive. It's much more difficult to select from them. Recommend to avoid this as much as possible.

## require-dbt-version
This is a recommended configuration.

Used to restrict your project, to only work with a range of dbt versions. dbt will send a helpful error message, for any user who attempts to run the project, with an unsupported version of dbt. 

This can be useful for package maintainers (such as dbt-utils), to ensure that users' dbt version is compatible with the package. 

Setting this configuration might also help your whole team remain synchronized, on the same version of dbt for local development, to avoid compatibility issues from changed behavior.

If this configuration is not specified, no version check will occur.

## snapshot-paths
Optionally specify a custom list of directories, where snapshots are located.

By default, dbt will search for snapshots in the "snapshots" directory. 

## model-paths
Optionally specify a custom list of directories, where models and sources are located.

By default, dbt will search for models and sources in the "models" directory. 

## target-path
(being deprecated in dbp_project.yml)

Optionally specify a custom directory, where compiled files will be written, when you run the dbt run, dbt compile, or dbt test command.

By default, dbt will write compiled files to the "target" directory. 

## test-paths
Optionally specify a custom list of directories, where singular tests are located.

By default, dbt will search for tests in the "tests" directory. 

## version
dbt projects have two distinct types of `version` tags. This field has a different meaning, depending on its location.

Starting in dbt version 1.5, `version` in the "dbt_project.yml" is an optional parameter. If used, the version must be in a semantic version format, such as 1.0.0. The default value is None.

Starting from version 1.5, `version` in your resource ".yml" files is optional.
