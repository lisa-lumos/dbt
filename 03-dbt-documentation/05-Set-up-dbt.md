# 5. Setup dbt
## About dbt setup
dbt Cloud: skipped.

dbt Core: open-source command line tool, that can be installed locally in your environment, and communication with databases is enabled through adapters.


## About environments
dev/prod

## dbt Cloud
### About dbt Cloud setup
The gear icon in the dbt Cloud UI. 

Prerequisites: dbt Cloud account, with admin access. 

### dbt Cloud environments
To execute dbt, environments define 3 variables:
- The dbt Core version to run your project
- The warehouse connection info,and the target db/schema
- The version of your code to execute

Each dbt Cloud project can have only one dev env, but can have any num of prod envs, providing flexibility/customization to execute scheduled jobs.

Each env is similar to an entry in dbt core "profiles.yml" file, with some additional info about your repo, to ensure the proper version of code is executed.

If you select a current version with "(latest)" in the name, your env will automatically install the latest stable version of the minor version selected.

By default, all envs will use the default branch in your repo (usually the main branch). This is overridable, within each dbt Cloud env, using the "Default to a custom branch" option. Depends on env type:
- in dev env, this is the branch where users create branches from, and PRs against
- in prod env, this is the branch cloned for job executions

To use the dbt Cloud IDE, each developer need to set up personal development credentials to your warehouse connection, in their Profile Settings. This users to set separate target info, and maintain individual credentials to connect to your warehouse.

Deployment environments in dbt Cloud are necessary to execute scheduled jobs. 

### Connect data platform
The following fields are required when creating a Snowflake connection:
- account
- role
- database
- warehouse

Ensure that users (in dev envs), and service accounts (in prod envs) have the correct permissions to take actions on Snowflake. 

Authentication methods:
- Username/password. Available in dev/prod env
- key pair auth. Available in dev/prod env
- Snowflake OAuth. Available in dev only. Need SF enterprise edition. 

### Manage access



### Configure Git



### Develop in the IDE



### Secure your tenant





## dbt Core



## Run your dbt projects



## Use threads






























