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

### Models
Models are primarily written as a "select" statement and saved as a ".sql" file. 

Starting in version 1.3, dbt Core/Cloud support Python models. They are useful for training/deploying data science models, complex transformations, or where a specific Python package meets a need - such as using the `dateutil` library to parse dates.

Your organization may need only a few models, but more likely you'll need a complex structure of nested models to transform the required data. 

### Seeds



### Snapshots



### Exposures



### Metrics




## Enhance your models
### Add tests to your DAG



### Materializations



### Incremental models





## Enhance your code
### Jinja and macros



### Project variables



### Environment variables



### Packages



### Analyses



Hooks and operations


## Organize your outputs
### Custom schemas



### Custom databases



### Custom aliases



### Custom target names














































