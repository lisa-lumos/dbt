# 8. Collaborate with others
## Explore dbt projects
With dbt Explorer, you can view your project's resources (such as models, tests, and metrics) and their lineage to gain a better understanding of its latest production state.

dbt Explorer automatically retrieves the metadata updates after each job run in the production deployment environment so it always has the latest results for your project.

## Git version control
### About git
skipped. 
### Version control basics
Some folders must be included in the gitignore file, to ensure dbt Cloud operates smoothly, such as target/logs/dbt_packages, etc. 

### Managed repository
If you do not already have a git repository for your dbt project, you can let dbt Cloud manage a repository for you. Managed repositories are a great way to trial dbt without needing to create a new repository.

### PR template
When changes are committed on a branch in the IDE, dbt Cloud can prompt users to open a new PR for the code changes. To enable this functionality, ensure that a PR Template URL is configured in the "Repository details page" in your Account Settings. If this setting is blank, the IDE will prompt users to merge the changes directly into their default branch.

### Merge conflicts
Merge conflicts in the dbt Cloud IDE often occur when multiple users are simultaneously making edits to the same section in the same file.

## Document your dbt projects
### About documentation
Good documentation for your dbt models will help downstream consumers discover and understand the datasets which you curate for them. 

### Build and view your docs with dbt Cloud
skipped

## Model governance
### About model governance
skipped

### Model access
Models can be grouped under a common designation with a shared owner. For example, you could group together all models owned by a particular team. 

Models can set an access modifier to indicate their intended level of accessibility. By default, all models are `protected`. This means that other models in the same project can reference them, regardless of their group. 

### Model contracts


### Model versions


### Project dependencies






