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
In dbt Cloud, there are two types of jobs:
- Deploy jobs. To create and set up triggers for building production data assets
- Continuous integration (CI) jobs. To create and set up triggers for checking code changes

### Deploy jobs
You must have a dbt Cloud account, and Developer seat license. 

Use tools such as crontab.guru to generate the correct cron syntax. 

### CI jobs
dbt Labs recommends that you create your CI job in a dedicated dbt Cloud deployment environment that's connected to a staging database. 

You can set the CI runs to be triggered by not only by pull requests, but also on draft pull request. 

You can set the commands to run during a CI job, the default is `dbt build -s state:modified+`, which runs only new/changed models and all their downstream models. 

Compare changes against an environment (Deferral): By default, it's set to the prod env. It allows dbt Cloud to check the state of the code in the PR, against the code running in the deferred environment, to only check the modified code, instead of building the full table or the entire DAG.

You can also trigger a CI job via the API. 

### Job commands
A dbt Cloud production job allows you to set up scheduled dbt job runs/commands, rather than running dbt commands manually from the command line or IDE. 

During a job run, the dbt built-in commands are chained together. If one of the run steps in the chain fails, then the next commands aren't executed, and the entire job fails with an "Error" status.

dbt Cloud executes the dbt source freshness command as the first run step in your job. If that particular run step in your job fails, the job can still succeed if all subsequent run steps are successful.

## Monitor jobs and alerts
View run history; Rerun jobs; job notifications; webhooks to sent job status to other systems; source freshness; ...

### Run visibility
View run history of the past year. 

View/download logs. 

View model timing dashboard, identify performance bottlenecks. 

### Retry jobs
If your dbt job run completed with a status of Error, you can rerun it from start or from the point of failure in dbt Cloud.

### Job notifications
Email/Slack notifications. 

### Webhooks
you can create outbound webhooks to send events (notifications) about your dbt jobs to your other systems. Your other systems can listen for (subscribe to) these events to further automate your workflows or to help trigger automation flows you have set up.

### Artifacts
for dbt docs and source freshness reporting. 

### Source freshness
When a dbt Cloud job is configured to snapshot source data freshness, dbt Cloud will render a user interface showing you the state of the most recent snapshot. This interface is intended to help you determine if your source data freshness is meeting the service level agreement (SLA) that you've defined for your organization.

As a good rule of thumb, you should run your source freshness jobs with at least double the frequency of your lowest SLA.

### Dashboard status tiles
In dbt Cloud, the Discovery API can power Dashboard Status Tiles. A Dashboard Status Tile is placed on a dashboard (specifically: anywhere you can embed an iFrame) to give insight into the quality and freshness of the data feeding into that dashboard. This is done via dbt exposures.

## Integrate with other tools
Schedule and run your dbt jobs with the help of tools such as Airflow, Prefect, Dagster, automation server, Cron, and Azure Data Factory (ADF)





























