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
dbt Cloud admins can use dbt Cloud's permissioning model to control user-level access in a dbt Cloud account. This access control comes in two flavors
- License-based Access Controls: User are configured with `account-wide license types`, which control what parts of the dbt Cloud app that a user can access.
- Role-based Access Control (RBAC): Users are assigned to `groups` that have specific permissions on specific projects, or the entire account. A user can be a member of multiple groups, which may have permissions on multiple projects.

Each user is assigned a license type, when they are first invited to the account. This license type may change over time, but a user can only have one license type at any given time.

dbt Cloud's 3 license types:
- Developer. User may be granted any permissions.
- Read-Only. User has read-only permissions to all dbt Cloud resources, which overrides user's role in RBAC.
- IT. User has Security/Billing Admin permissions, which overrides user's role in RBAC.

RBAC is a feature of the dbt Cloud Enterprise plan. Allows for fine-grained permissioning in the dbt Cloud. Users can have diff permissions to diff projects. Role-based permissions can be generated dynamically, from configurations in an Identity Provider. So dbt Cloud admins can manage access to dbt Cloud via identity management software, like Azure AD, Okta, or GSuite. 

Role-based permissions are applied to groups, and pertain to projects. The assignable permissions are created via permission sets.

A group is a collection of users. Members of a group inherit any permissions applied to the group. SSO Mappings connect IdP group membership to dbt Cloud group membership.

Permission sets are predefined collections of granular permissions. They are high-level roles, that can then be assigned to groups. Some examples of existing permission sets are:
- Account Admin
- Git Admin
- Job Admin
- Job Viewer
- ...

dbt Cloud admin can manually assign users to groups, independently of IdP attributes.

Group memberships are updated, whenever a user logs into dbt Cloud via SSO. If you've changed group memberships in your idP or dbt Cloud, ask your users to log back into dbt Cloud to synchronize these group memberships.

To edit the group membership of yourself, you'll need a different user to do this.


















### Configure Git



### Develop in the IDE



### Secure your tenant





## dbt Core



## Run your dbt projects



## Use threads






























