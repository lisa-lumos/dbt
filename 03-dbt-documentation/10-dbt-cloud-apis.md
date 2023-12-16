# 10. dbt Cloud APIs
## APIs Overview
dbt Cloud provides the following APIs:
- The dbt Cloud Administrative API: To administrate a dbt Cloud account.
- The dbt Cloud Discovery API: To fetch metadata related to the state/health of your dbt project.
- The dbt Semantic Layer APIs provides multiple API options, which allow you to query your metrics defined in the dbt Semantic Layer.

dbt Cloud supports two types of API Tokens: user tokens, and service account tokens. 

## Authentication
### User tokens
Each dbt Cloud user with a Developer license is given an API token, which can be used to execute queries against the dbt Cloud API, on the user's behalf.

### Service account tokens
Service account tokens enable you to securely authenticate with the dbt Cloud API, by assigning each token a narrow set of permissions, that more precisely manages access to the API. Service account tokens belong to an account, rather than a user.

You can use service account tokens for system-level integrations, that do not run on behalf of a user. 

## Administrative API
The dbt Cloud Administrative API is enabled by default, for Team and Enterprise plans. 

It can be used to:
- Download artifacts after a job has completed
- Kick off a job run from an orchestration tool
- Manage your dbt Cloud account
- ...

## Discovery API
Used for getting metadata on your dbt project. 

By leveraging the metadata in dbt Cloud, you can create systems for data monitoring and alerting, lineage exploration, and automated reporting. This can help you improve data discovery, data quality, and pipeline operations, within your organization.

## Semantic Layer APIs




