# 4. Commands
## dbt Command reference
skipped.

## Node selection
### Syntax overview
By default, `dbt run` executes all of the models in the dependency graph; `dbt seed` creates all seeds, `dbt snapshot` performs every snapshot. The `--select` flag is used to specify a subset of nodes to execute.

Short hand of `--select` is `-s`. 

Examples of `-s`:
```
dbt run -s "my_dbt_project_name"   # runs all models in your project
dbt run -s "my_dbt_model"          # runs a specific model
dbt run -s "path.to.my.models"     # runs all models in a specific directory
dbt run -s "my_package.some_model" # run a specific model in a specific package
dbt run -s "tag:nightly"           # run models with the "nightly" tag
dbt run -s "path/to/models"        # run models contained in path/to/models
dbt run -s "path/to/my_model.sql"  # run a specific model by its path
```

You can use a predefined definition with the `--selector` flag.

One of the greatest underlying assumptions about dbt, is that its operations should be stateless and idempotent. That is, it doesn't matter how many times a model has been run before, or if it has ever been run before. It doesn't matter if you run it once or a thousand times. Given the same raw data, you can expect the same transformed result. A given run of dbt doesn't need to "know" about any other run; it just needs to know about the code in the project and the objects in your database, as they exist right now.

dbt can leverage artifacts from a prior invocation, as long as their file path is passed to the `--state` flag. 

Another element of job state is the `result` of a prior dbt invocation. After executing a dbt run, dbt creates the run_results.json artifact, which contains execution times and success/error status for dbt models. 

When a job is selected, dbt Cloud will surface the artifacts from that job's most recent successful run. dbt will then use those artifacts to determine the set of `fresh` sources. In your job commands, you can signal to dbt to run and test only on these fresher sources and their children, by including the `source_status:fresher+` argument. This requires both previous and current state to have the sources.json artifact be available. 

### Graph operators
```
dbt run --select my_model+         # select my_model and all children
dbt run --select +my_model         # select my_model and all parents
dbt run --select +my_model+        # select my_model, and all of its parents and children

dbt run --select my_model+1        # select my_model and its first-degree children
dbt run --select 2+my_model        # select my_model, its first-degree parents, and its second-degree parents (grandparents)
dbt run --select 3+my_model+4      # select my_model, its parents up to the 3rd degree, and its children down to the 4th degree

dbt run --models @my_model         # select my_model, its children, and the parents of its children
```

### Set operators
space ` ` between arguments means union, while comma `,` between arguments means intersection. 

```
dbt run --select "+snowplow_sessions +fct_orders" # union (or)

dbt run --select "stg_invoices+,stg_accounts+"    # intersection (and)
dbt run --select "marts.finance,tag:nightly"      # intersection (and)
```

### Exclude
Models specified with the `--exclude` flag will be removed from the set of models selected with `--select`.

```
dbt run --select "my_package".*+ --exclude "my_package.a_big_model+"    # select all models in my_package and their children, except a_big_model and its children
```

### Methods
Such as tag, source, ...

Examples:

```
dbt run --select "tag:nightly"    # run all models with the nightly tag

dbt run --select "source:snowplow+"    # run all models downstream of Snowplow sources

dbt build --select "resource_type:exposure"    # build all resources upstream of exposures
dbt list --select "resource_type:test"    # list all tests in your project

# These two selectors are equivalent
dbt run --select "path:models/staging/github"
dbt run --select "models/staging/github"

# These two selectors are equivalent
dbt run --select "path:models/staging/github/stg_issues.sql"
dbt run --select "models/staging/github/stg_issues.sql"

dbt run --select "package:snowplow"

dbt run --select "config.materialized:incremental" # run all models that are materialized incrementally

dbt test --select "test_type:generic"        # run all generic tests
dbt test --select "test_type:singular"       # run all singular tests

dbt test --select "test_name:unique"            # run all instances of the `unique` test
dbt test --select "test_name:equality"          # run all instances of the `dbt_utils.equality` test
dbt test --select "test_name:range_min_max"     # run all instances of a custom schema test defined in the local project, `range_min_max`

dbt test --select "state:new "           # run all tests on new models + and new tests on old models
dbt run --select "state:modified"        # run all models that have been modified
dbt ls --select "state:modified"         # list all modified nodes (not just models)

dbt run --select "+exposure:weekly_kpis"                # run all models that feed into the weekly_kpis exposure
dbt test --select "+exposure:*"                         # test all resources upstream of all exposures
dbt ls --select "+exposure:*" --resource-type source    # list all sources upstream of all exposures

dbt build --select "+metric:weekly_active_users"       # build all resources upstream of weekly_active_users metric
dbt ls    --select "+metric:*" --resource-type source  # list all source tables upstream of all metrics

dbt run --select "result:error" --state path/to/artifacts # run all models that generated errors on the prior invocation of dbt run
dbt test --select "result:fail" --state path/to/artifacts # run all tests that failed on the prior invocation of dbt test
dbt build --select "1+result:fail" --state path/to/artifacts # run all the models associated with failed tests from the prior invocation of dbt build
dbt seed --select "result:error" --state path/to/artifacts # run all seeds that generated errors on the prior invocation of dbt seed.

# You can also set the DBT_STATE environment variable instead of the --state flag.
dbt source freshness # must be run again to compare current to previous state
dbt build --select "source_status:fresher+" --state path/to/prod/artifacts

dbt run --select "group:finance" # run all models that belong to the finance group.

dbt list --select "access:public"      # list all public models
dbt list --select "access:private"       # list all private models
dbt list --select "access:protected"       # list all protected models

dbt list --select "version:latest"      # only 'latest' versions
dbt list --select "version:prerelease"  # versions newer than the 'latest' version
dbt list --select version:old         # versions older than the 'latest' version
dbt list --select "version:none"        # models that are *not* versioned

dbt list --select semantic_model:*        # list all semantic models 
dbt list --select +semantic_model:orders  # list your semantic model named "orders" and all upstream resources

```

### Putting it together
skipped

### YAML Selectors
Write resource selectors in YAML, save them with a human-friendly name, and reference them using the `--selector` flag.

### Test selection examples
```console
dbt test --select "test_type:generic"
dbt test --select "test_type:singular"

# eager mode:
dbt test --select "orders"
dbt build --select "orders"

# cautious:
dbt test --select "orders" --indirect-selection=cautious
dbt build --select "orders" --indirect-selection=cautious

# buildable:
dbt test --select "orders" --indirect-selection=buildable
dbt build --select "orders" --indirect-selection=buildable

# Empty:
dbt test --select "orders" --indirect-selection=empty
dbt build --select "orders" --indirect-selection=empty

```

The modes to configure the behavior when performing indirect selection:
1. eager (default) - include ANY test that references the selected nodes, even if it references other models as well.
2. cautious - restrict to tests that ONLY refer to selected nodes
3. buildable - restrict to tests that ONLY refer to selected nodes, or their ancestors
4. empty - restrict to tests that are only for the selected node, and ignore all tests from the attached nodes

The "buildable", "cautious", and "empty" modes can be useful in environments when you're only building a subset of your DAG, and you want to avoid test failures in "eager" mode caused by unbuilt resources. (Another way to achieve this is with deferral).

### Defer
Defer is a powerful feature that makes it possible to run a subset of models or tests in a sandbox environment, without having to first build their upstream parents. This can save time and computational resources when you want to test a small number of models in a large project.

### Caveats to state comparison
Only seeds <1mb can be detected for changes. 

vars change cannot be detected. 

## List of commands
### build
The dbt build command will:
- run models
- test tests
- snapshot snapshots
- seed seeds

Tests on upstream resources will block downstream resources from running, and a test failure will cause those downstream resources to skip entirely. Adjust its severity or thresholds to warn instead of error, to avoid skipping. 

### clean
Deletes all folders specified in the "clean-targets" list specified in "dbt_project.yml". 

Doesn't work for dbt Cloud. 

### clone
The dbt clone command clones selected nodes from the specified state to the target schema(s). This command makes use of the clone materialization. 

### docs
The command is responsible for generating your project's documentation website by:
1. Copying the website "index.html" file into the "target/" directory
2. Compiling the resources in your project, so that their compiled_code will be included in "manifest.json"
3. Running queries against database metadata to produce the "catalog.json" file, which contains metadata about the tables and views produced by the models in your project.

### compile
Generates executable SQL from source model/test/analysis files. You can find these compiled SQL files in the "target/" directory of your dbt project.

Starting in dbt v1.5, compile can be "interactive" in the CLI, by displaying the compiled code of a node, or arbitrary dbt-SQL query. 

### debug
Test the database connection, and display information for debugging purposes, such as the validity of your project file, and your installation of any requisite dependencies. 

### deps
Pulls the most recent version of the dependencies listed in your "packages.yml" from git.

Starting in dbt Core v1.7, dbt generates a "package-lock.yml" file in the root of your project. 

### environment
Enables you to interact with your dbt Cloud environment. Can be used for:
- Viewing your local config details (account ID, active project ID, deployment environment, ...).
- Viewing your dbt Cloud config details (environment ID, environment name, connection type, ...).

### init
Initializes a dbt core project. 

### ls (list)
Lists resources in your dbt project.

### parse
parses and validates the contents of your dbt project. If your project contains Jinja or YAML syntax errors, the command will fail.

### retry
Re-executes the last dbt command, from the node point of failure. 

### rpc
(deprecated)

### run
Executes compiled sql model files against the current target database. 

### run-operation
Used to invoke a macro.

### seed
skipped. 

### show
Preview a model/test/analysis in terminal. 

### snapshot
skipped

### source
Test source freshness. 

### test
Runs tests defined on models/sources/snapshots/seeds.

### version
The currently installed version of dbt Core, or the dbt Cloud CLI.

## Flags (global configs)
Configurations for fine-tuning how dbt runs your project.

Logs: how dbt's logs should be formatted, the minimum severity of events captured in the console and file logs, suppress non-error logs in output, etc. 

Cache: skipped. 

Failing fast: make dbt exit immediately if a single resource fails to build. If other models are in-progress when the first model fails, then dbt will terminate the connections for these still-running models.

JSON artifacts: determines whether dbt writes JSON artifacts

Legacy behaviors: skipped

Parsing: partial parsing; static parser

Print output: deprecated. 

Record timing info: saves performance profiling information to a file.

Anonymous usage stats: skipped. 

Checking version compatibility

Warnings: convert dbt warnings into errors.

## Events and logs
For debug logs. 

## Exit codes
skipped. 

## Project Parsing
Parsing: At the start of every dbt invocation, dbt reads all the files in your project, extracts information, and constructs a manifest containing every object. 

There are ways to make this process faster, but each have their own limitations. 

## Programmatic invocations
You can call dbt run etc from Python. 
