# 6. Build dbt projects
## About dbt projects
In a project, dbt enforces the top-level structure:
- "dbt_project.yml" file
- models/snapshots/seeds/tests/macros/docs/sources/exposures/metrics/analysis/... directories

Within these directories of the top-level, you can organize your project in any way, that meets the needs of your organization and data pipeline.

When building out the structure of your project, consider these impacts on your organization's workflow:
- How would people run dbt commands - Selecting a path
- How would people navigate within the project - Whether as developers in the IDE, or stakeholders from the docs
- How would people config the models - Some bulk configs are easier done at the directory level, so people don't have to remember to do everything in a config block, with each new model

"dbt_project.yml" commonly contains these proj configs:
- name: Project name in snake case (Python convention)
- version: Version of your project
- require-dbt-version: Restrict your proj to only work with a range of dbt Core versions
- profile: The profile dbt uses, for data platform connection
- model-paths: Dirs to model/source files
- seed-paths: Dirs to seed files
- test-paths: Dirs to test files
- analysis-paths: Dirs to analyses
- macro-paths: Dirs to macros
- snapshot-paths: Dirs to snapshots
- docs-paths: Dirs to docs blocks
- vars: Proj variables for data compilation

In dbt Cloud, you can use the "Project subdirectory" option, to specify a subdir in your git repo, as the root dir for your dbt project. This is helpful, when you have multiple dbt projects in one repository, or when you want to organize your dbt project files into subdirs for easier management.

If you want to see what a mature, production project looks like, check out the "GitLab Data Team public repo": https://gitlab.com/gitlab-data/analytics/-/tree/master/transform/snowflake-dbt.

## Build your DAG
### Models
Models are primarily written as a "select" statement and saved as a ".sql" file. 

Starting in version 1.3, dbt Core/Cloud support Python models. They are useful for training/deploying data science models, complex transformations, or where a specific Python package meets a need - such as using the `dateutil` library to parse dates.

Your organization may need only a few models, but more likely you'll need a complex structure of nested models to transform the required data. 

#### SQL Models
The model name is inherited from the file name. Models can be nested in subdirs within the "models" directory. 

When you execute "dbt run ...", dbt will build this model, by wrapping it in a "create view as" or "create table as" statement.

Your should write the models using the SQL flavor of your own data platform. 

Model configs can be set in your "dbt_project.yml" file, and in that model file using a "{{ config(...) }}" block.

Configurations include:
- Change the model's materialization
- Build models into separate schemas.
- Apply tags to a model.
- aliases
- hooks
- ...

Configs are applied hierarchically - a more specific one will override any less specific ones.

You can build dependencies between models by using the "{{ ref('...') }}" in place of table names in a query. 

dbt uses the ref function to:
- Determine the order to run the models, by creating a dependent acyclic graph (DAG).
- Manage separate envs. dbt will prefix the referred model name with the db & schema name. Importantly, this is environment-aware, because dev and prod use diff schemas. 

The ref function encourages you to write modular transformations, so that you can re-use models, and reduce repeated code.

If you wish to use insert statements for performance reasons, consider incremental models. 

If you wish to use insert statements since your source data is constantly changing (e.g. to create "Type 2 Slowly Changing Dimensions"), you can snapshot your source data, and building models on top of your snapshots.

#### Python Models
Snowflake uses its own framework, Snowpark, which has many similarities to PySpark.

dbt Python models can help you solve use cases that can't be solved with SQL.

In a dbt Python model, all Python code is executed remotely on the platform. None of it is run by dbt locally. 

A dbt Python model is a function that reads in dbt sources/models, applies transformations, and returns a transformed dataset. DataFrame operations define the starting points, the end state, and each step along the way. Each Python model returns a final DataFrame.

Each DataFrame operation is "lazily evaluated." In dev, you can preview its data, using methods like .show() or .head(). When you run a Python model, the full result of the final DataFrame will be saved as a table in your data warehouse.

dbt Python models have access to almost all of the same config options as SQL models.

Each Python model lives in a ".py" file in your "models/" folder. It defines a function named model(), which takes two parameters:
- dbt: A class compiled by dbt Core, unique to each model, enables you to run your Python code in the context of your dbt project and DAG.
session: A class representing your data platform's connection to the Python backend. The session is needed to read in tables as DataFrames, and to write DataFrames back to tables. 

The model() function must return a single DataFrame. On Snowpark (Snowflake), this can be a Snowpark or pandas DataFrame.

This is how every single Python model should look:
```py
def model(dbt, session):
    ...
    return final_df
```

Use the `dbt.ref()` within a Python model, to read data from other SQL/Python models. Use `dbt.source()` to read a source table. 

Note that, referencing ephemeral models is currently not supported. 

Just like SQL models, there are three ways to config Python models. 

Python models support 2 materializations:
- table (default)
- incremental

In addition to defining a model function, the Python model can import other functions, or define its own. 

You can use the `@udf` decorator or `udf` function to define an "anonymous" function and call it within your model function's DataFrame transformation. 

Limitations of Python models:
- Time and cost. Python models are slower to run than SQL models, and the cloud resources that run them can be more expensive.
- Syntax differences are even more pronounced. If there are 5 ways to do something in SQL, there are 500 ways to write it in Python, all with varying performance and adherence to standards.
- These capabilities are very new. 
- Lack of `print()` support. 

### Snapshots
Records changes to a mutable table over time (SCD-2).

In dbt, snapshots are select statements, defined within a "snapshot block" in a sql file, typically in your "snapshots" folder. 

Such as "snapshots/orders_snapshot.sql":
```sql
{% snapshot orders_snapshot %}

{{
    config(
      target_database='analytics',
      target_schema='snapshots',
      unique_key='id',

      strategy='timestamp',
      updated_at='updated_at',
    )
}}

select * from {{ source('jaffle_shop', 'orders') }}

{% endsnapshot %}
```

When you run the dbt snapshot command:
- On the first run: dbt will create the initial snapshot table, which is the result set of your select statement, with additional columns, such as: `dbt_valid_from`/`dbt_valid_to`. All records will have a `dbt_valid_to` = `null`.
- On subsequent runs: dbt will check which records have changed, or if any new records have been created. The `dbt_valid_to` will be updated for any existing records that have changed. The updated record and any new records will be inserted into the snapshot table. These records will now have `dbt_valid_to` = `null`

Snapshots can be referenced in downstream models with `ref(...)`.

There are two snapshot strategies built-in to dbt:
1. Timestamp strategy (recommended). uses an `updated_at` field to determine if a row has changed. 
   - If the `updated_at` for a row is more recent than the last time the snapshot ran (how does dbt know when it was last run? Based on the `dbt_updated_at` val for this row), then dbt will:
     - Invalidate the old record, setting its `dbt_valid_to` to the `updated_at` val.
     - Record the new one, setting its `dbt_valid_from` to the `updated_at` val. 
   - If the timestamps are unchanged, then dbt will do nothing.
2. Check strategy. Useful for tables without a reliable `updated_at` column. Works by comparing current and historical values for a list of cols. If any of these cols changed, dbt will invalidate the old record, and record the new one. If the column values are identical, then dbt will do nothing.

Rows that are deleted from the source are not invalidated (sealed up) by default. With the config option `invalidate_hard_deletes`, dbt can track rows that no longer exist, and set `dbt_valid_to` to the current snapshot time.

Snapshot-specific configs:
- target_database. Optional
- target_schema. Required
- strategy. Required
- unique_key. Required
- check_cols. Required if using check strategy
- updated_at. Required if using timestamp strategy
- invalidate_hard_deletes. Optional

It's extremely important, to make sure this unique key is actually unique. 

Recommend to use a `target_schema` that is separate to your analytics schema. Snapshots CANNOT be rebuilt. As such, it's a good idea to put snapshots in a separate schema, so end users know they are special. 

Snapshot best practices: 
- Snapshot source data. As much as possible, snapshot your source data in its raw form, and use downstream models to clean up the data. Your models should select from these snapshots, treating them like data sources. 
- Use the `source(...)` in your query. Helps with the lineage. 
- Include as many columns as possible. Go for `select *` if performance permits.  
- Avoid joins in your snapshot directly. It makes it difficult to build a reliable `updated_at` timestamp. Instead, snapshot the two tables separately, and join them in downstream models.
- Limit the amount of transformation in it. To be future-proof. 

The dbt snapshot command must be run on a schedule, to ensure that changes to tables are actually recorded. While individual use-cases may vary, snapshots are intended to be run `between hourly and daily`. If you find yourself snapshotting more frequently than that, consider to capture changes in your source data tables.

You can select with snapshot to run, with `--select`. 

When the columns of your source query changes, dbt will attempt to reflect this change in the destination snapshot table:
- Create new columns in destination table, if new cols added in the source
- Expand the size of string types where necessary (eg. varchars on Redshift)

dbt will NOT delete columns in the destination snapshot table, if they are removed from the source. It will NOT change the datatype of a column, beyond expanding the size of varchar columns. If a string column is changed to a date column in the source, dbt will not change the datatype of the column in the destination table.

Snapshots build into the same `target_schema`, no matter who is running them, and is "not environment-aware" by default. In comparison, models build into a separate schema for each user - this helps maintain separate dev/prod envs.

### Seeds
Seeds are CSV files in your dbt project (typically in your "seeds" dir), that dbt can load into your data warehouse, using the `dbt seed` command (behind the scene, it is a truncate and load, if the table already exists).

Seeds can be referenced in downstream models, the same way as models.

Because these CSV files are located in your dbt repository, they are version controlled and code reviewable. Seeds are best suited to static data which changes infrequently.

Good use-cases for seeds: mappings of country codes to country names, test emails list to exclude from analysis, employee account ID list. 

Poor use-cases of dbt seeds: Raw data that has been exported to CSVs; production data containing sensitive information.

You can document/test seeds in YAML, by declaring properties. 

If you changed the columns of your seed, you may get a Database Error. In this case, you can run `dbt seed --full-refresh`. 

dbt will infer the datatype for each column based on the data in your CSV. You can also explicitly set a datatype using the `column_types` config in the yml file. Works when you need to preserve leading zeros (in a zipcode, or mobile number). 

You can run models downstream of a seed, using the same model selection syntax, treating the seed like a model.

You can use `--select` in the `dbt seed` command, to run a specific seed. 

Hooks work with seeds too. 

### Tests
Tests are assertions you make about your models/sources/seeds/snapshots. When you run `dbt test`, dbt will tell you if each test passes/fails.

Tests are SQL select statements that seek to grab "failing" records. If the test returns 0 failing rows, it passes, and your assertion has been validated.

#### Generic test
Out of the box, you can test `unique`, `not_null`, `accepted_values` and `relationships` (referential integrity). You use them in yml files. Such as:
```yml
version: 2

models:
  - name: orders
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
      - name: status
        tests:
          - accepted_values:
              values: ['placed', 'shipped', 'completed', 'returned']
      - name: customer_id
        tests:
          - relationships:
              to: ref('customers')
              field: id
```

You can also install generic tests from a package, or write your own. Generic tests tend to be much more common - they should make up the bulk of your dbt testing suite.

#### Singular test
You can extend tests to suit business logic specific to your organization. Any select query can be turned into a test, in the "test" folder. 

Singular test example "tests/assert_total_payment_amount_is_positive.sql":
```sql
select
    order_id,
    sum(amount) as total_amount
from {{ ref('fct_payments' )}}
group by 1
having not(total_amount >= 0)
```

If you find yourself writing the same basic structure over and over, consider converting it into a generic test, which takes arguments. Such as the below definition:
```sql
{% test not_null(model, column_name) %}
    select *
    from {{ model }}
    where {{ column_name }} is null
{% endtest %}
```

The parameters makes the test "generic". Then, you can use it in yml files. 

#### Summary
Normally, a test query will calculate failures as part of its execution. 

If you set the optional `--store-failures` flag or `store_failures` in config, dbt will save test query results to the table `dbt_test__audit`, and then query that table, to calculate the number of failures.

You can then query the table directly (dbt will give you the command to run in command output), and examine failing records much more quickly, in dev. 

In this table, a test's results will always replace prev failures, for the same test.

Commands: 
- To test a specific model: `dbt test --select my_model`
- To test all sources: `dbt test --select source:*`
- To test one source (including all tables inside it): `dbt test --select source:jaffle_shop`
- To test one table in a source: `dbt test --select source:jaffle_shop.orders`

Recommendations:
- Every model has a test on a primary key
- Test any assumptions on your source data
- In advanced dbt projects, use sources, and run these source data-integrity tests against the sources, rather than models.

You should run your tests whenever you are writing new code (to ensure you haven't broken any existing models by changing SQL), and, whenever you run jobs in prod (to ensure that your assumptions about your source data are still valid).

You can use the `error_if`/`warn_if` configs, to set custom failure thresholds in your tests.

To test a composite primary key, the the `dbt_utils.unique_combination_of_columns test` is most performant. 

### Jinja and macros



### Sources
Sources make it possible to name/describe the source data. By declaring them as sources in dbt, you can then:
- refer to them in your models: `{{ source('source_schema_name', 'source_table_name') }}`
- run tests on them
- check their freshness

Sources are defined in ".yml" files, under a `sources:` key:
```yml
version: 2

sources:
  - name: jaffle_shop
    database: raw  
    schema: jaffle_shop  
    tables:
      - name: orders
      - name: customers

  - name: stripe
    tables:
      - name: payments
```

Note that, 
- By default, `schema` will be the same as source `name`. Add `schema` only if you want to use a source name, that differs from the existing schema name. 
- Use `database: ` if the source is in a diff db than dbt target db. 
- For snowflake, if you need to quote obj name, use the `quoting` property.

To have tests on sources:
```yml
version: 2

sources:
  - name: jaffle_shop
    description: This is a replica of the Postgres database used by our app
    tables:
      - name: orders
        description: >
          One record per order. Includes cancelled and deleted orders.
        columns:
          - name: id
            description: Primary key of the orders table
            tests:
              - unique
              - not_null
          - name: status
            description: Note that the status can change over time

      - name: ...

  - name: ...
```

To run tests on sources:
```console
# test all sources: 
$ dbt test --select source:*

# test only one source (schema) name: 
$ dbt test --select source:jaffle_shop

# test one source table name:
$ dbt test --select source:jaffle_shop.orders
```

To run models downstream of a source:
```console
# run models downstream of a source (schema) name:
$ dbt run --select source:jaffle_shop+

# run models downstream of a source table name: 
$ dbt run --select source:jaffle_shop.orders+
```

Source freshness checks are useful for understanding if your data pipelines are healthy, and is a critical component of defining SLAs for your warehouse.

To check source freshness:
```yml
version: 2

sources:
  - name: jaffle_shop
    database: raw
    freshness: # default freshness
      warn_after: {count: 12, period: hour}
      error_after: {count: 24, period: hour}
    loaded_at_field: _etl_loaded_at # required to check freshness

    tables:
      - name: orders
        freshness: # make this a little more strict
          warn_after: {count: 6, period: hour}
          error_after: {count: 12, period: hour}

      - name: customers # uses the freshness defined for the schema

      - name: product_skus
        freshness: null # do not check freshness for this table
```

The command `dbt source freshness` checks freshness of sources. 

### Exposures
Define/describe downstream uses of your dbt project, such as in a dashboard, application, or data science pipeline.

By defining exposures, you can then:
- run/test/list resources that feed into your exposure
- populate a dedicated page in the auto-generated documentation site, with context relevant to data consumers

Exposures are defined in yml files:
```yml
version: 2

exposures:

  - name: weekly_jaffle_metrics # required
    label: Jaffles by the Week
    type: dashboard # required. Can be dashboard/notebook/analysis/ml/application
    maturity: high
    url: https://bi.tool/dashboards/1
    description: >
      Did someone say "exponential growth"?

    depends_on: # expected. 
      - ref('fct_orders')
      - ref('dim_customers')
      - source('gsheets', 'goals')
      - metric('count_orders')

    owner: # required. name or email
      name: Callum McData
      email: data@jaffleshop.com
```

Once an exposure is defined, you can run commands that reference it:
- `dbt run -s +exposure:weekly_jaffle_report`
- `dbt test -s +exposure:weekly_jaffle_report`

### Metrics
The `dbt_metrics` package has been deprecated, and replaced with `MetricFlow`, a new framework for metrics in dbt. The new Semantic Layer is available to Team/Enterprise multi-tenant dbt Cloud plans hosted in North America. You must be on dbt v1.6 &+ to access it. 


### Groups


### Analyses

## Build your metrics

### Get started with MetricFlow

### About MetricFlow
#### Joins

#### Validations

#### MetricFlow time spine

#### MetricFlow CLI commands

### Semantic models
#### Dimensions

#### Entities

#### Measures

### Metrics
#### Cumulative

#### Derived

#### Ratio

#### Simple


## Enhance your models
### Materializations



### Incremental models





## Enhance your code
### Project variables



### Environment variables



### Packages


### Hooks and operations


## Organize your outputs
### Custom schemas



### Custom databases



### Custom aliases



### Custom target names













































