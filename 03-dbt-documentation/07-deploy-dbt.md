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


## Continuous integration


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






























