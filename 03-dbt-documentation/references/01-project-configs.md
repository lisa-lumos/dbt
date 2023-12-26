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


## profile


## query-comment


## quoting


## require-dbt-version


## snapshot-paths


## model-paths


## target-path


## test-paths


## version






































