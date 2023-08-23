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








### Models



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














































