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


### Exclude


### Methods


### Putting it together


### YAML Selectors


### Test selection examples


### Defer


### Caveats to state comparison

## List of commands



## Global configs



## Global CLI flags



## Events and logs



## Exit codes



## Project Parsing



## Programmatic invocations













