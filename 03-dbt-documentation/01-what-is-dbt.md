# 1. What is dbt?
dbt is a transformation workflow, that compiles/runs your analytics code against your data platform. 

It enables your team to collaborate on a single source of truth for metrics, insights, and business definitions. 

Write business logic with just a SQL select statement, or a Python DataFrame, that returns the dataset you need, and dbt takes care of materialization.

Write DRY code, by leveraging macros, hooks, and package management. Change a model once, and that change will propagate to all its dependencies.

Use mature source control processes, like branching, pull requests, and code reviews.

Write data quality tests, quickly and easily on the underlying data. Many analytic errors are caused by edge cases in the data: testing helps find/handle them.

You can access dbt using dbt Core or dbt Cloud. 

dbt Cloud is built around dbt Core, but it also provides:
- Web-based UI, so it's more accessible
- Hosted environment, so it's faster to get up and running
- Differentiated features, such as metadata, in-app job scheduler, observability, integrations with other tools, IDE, ...
