# 7. Deploy dbt
## Deploy dbt
Rather than run dbt commands manually from the command line, you can leverage the dbt Cloud's in-app scheduling, to automate how/when you execute dbt.

## Job scheduler
The backbone of running jobs in dbt Cloud. 

The scheduler enables both cron-based, and event-driven execution of dbt commands:
- Cron-based execution of dbt Cloud jobs, that run on a predetermined cadence
- Event-driven execution of dbt Cloud CI jobs, triggered by pull requests to the dbt repo
- Event-driven execution of dbt Cloud jobs, triggered by API
- Event-driven execution of dbt Cloud jobs, manually triggered by a user to "Run Now"

Run slots control the number of jobs that can run concurrently. Developer/Team plan accounts have a fixed number of run slots, Enterprise users have unlimited run slots.

The thread count is the maximum number of paths through the DAG that dbt can work on simultaneously. The default thread count in a job is 4.

CI runs don't consume run slots and will never block production runs. CI runs can execute concurrently (in parallel). CI runs build into unique temporary schemas. 

In dbt Cloud, the setting to provision memory available to a job is defined at the account-level and applies to each job running in the account; the memory limit cannot be customized per job. If a running job reaches its memory limit, the run is terminated with a "memory limit error" message.

The scheduler prevents queue clog by canceling runs that aren't needed, ensuring there is only one run of the job in the queue, at any given time. If a newer run is queued, the scheduler cancels any previously queued run for that job, and displays an error message.

## Deployment environments
envs determine the settings used during job runs, including:
- The version of dbt Core used to run the project
- The warehouse connection info, the target database/schema settings
- The version of your code to execute

Each dbt Cloud project can only have a single development environment but can have any number of deployment(prod) environments.

By default, all envs will use the default branch in your repo (usually the main branch), when accessing your dbt code. This is overridable within each dbt Cloud Environment, using the "Default to a custom branch" option.

Warehouse connections are set at the Project level for dbt Cloud accounts, and each Project can have one connection (Snowflake account, Redshift host, Bigquery project, Databricks host, etc.).

## Continuous integration (CI)
You can set up automation, that tests code changes, by running CI jobs before merging to production. Only the modified data assets in your PR, and their downstream dependencies, are built/tested in a staging schema. 

You can also view the status of the CI checks from within the PR; this info is posted to your Git provider, as soon as a CI job completes. 

You can enable settings in your Git provider, that only allow PRs with successful CI checks be approved for merging.

CI could:
- Provide increased confidence and assurances that project changes will work as expected in prod.
- Reduce the time it takes to push code changes to prod, through build/test automation, leading to better business outcomes.
- Allow organizations to make code changes in a standardized/governed way that ensure code quality, without sacrificing speed.

If CI jobs are already set up, dbt Cloud listens for webhooks from your Git provider indicating that a new PR has been opened/updated, with new commits. When dbt Cloud receives one of these webhooks, it enqueues a new run of the CI job.

In a temporary schema, unique to the PR, dbt Cloud builds and tests the models affected by the code change. It ensures that the code builds without error, and that it passes the dbt tests.

dbt Cloud deletes the temporary schema from your data warehouse, when you close/merge the pull request. 

CI runs can be concurrent, because different PR's CI runs generate results in different temp schemas. For CI runs within the same PR, they can be serial. 

When you push a new commit to a PR, dbt Cloud enqueues a new CI run for the latest commit, and cancels any CI run that is (now) stale and still running. 

## Jobs
### About Jobs










### Deploy jobs

### CI jobs

### Job commands


## Monitor jobs and alerts

### Monitor jobs and alerts

### Run visibility

### Retry jobs

### Job notifications

### Webhooks

### Artifacts

### Source freshness

### Dashboard status tiles

## Integrate with other tools






























