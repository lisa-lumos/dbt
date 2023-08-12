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
- Developer. For dev/prod features. User may be granted any permissions.
- Read-Only. User has read-only permissions to all dbt Cloud resources, which overrides user's role in RBAC.
- IT. For managing permissions. User has Security/Billing Admin permissions, which overrides user's role in RBAC.

Each dbt Cloud plan comes with a base number of Developer, IT, and Read-Only licenses. You can add/remove licenses, by modifying the num of users in your account settings. By default, new users will be assigned a Developer license.

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

dbt Cloud supports two permission sets, to manage permissions for self-service accounts: Member and Owner.

The dbt Cloud Enterprise plan supports a number of pre-built R/W account/project level permission sets to help manage access controls. Account roles enable you to manage the dbt Cloud account and manage the account settings. The project roles enable you to work within the projects in various capacities.

SSO/Oauth are available for Enterprise plan only. 

dbt provides logs of audited user/system events in real time. You must be an Account Admin to access the audit log, and this feature is only available on Enterprise plans.

Events within 90 days will be automatically displayed with a selectable date range. Older event can be exported directly. 

### Configure Git
dbt Cloud uses the SSH protocol to clone repositories, so dbt Cloud will be unable to clone repos supplied with the HTTP protocol.

### Develop in the IDE
To improve your experience using dbt Cloud, turn off ad blockers. Some project file names, such as "google_adwords.sql", might resemble ad traffic, and trigger ad blockers. 

Multiple selections: Option and click on an area, or Ctrl-Alt and click on an area. 

Autocomplete features:
- `ref` for model names
- `source` for source/table name
- `macro` for arguments
- `env var` for env vars
- `-` in a YAML file

3 Cloud IDE start-up states:
- Creation start. Starting the IDE for the first time. Like a cold start, takes longer, because the git repo is being cloned.
- Cold start. Starting a new develop session. Turns off after if no compile/preview/invocation activity for 3 hrs. 
- Hot start. Resuming an existing/active develop session, within 3 hours of the last compile/preview/invocation activity.

Saved changes live forever. You can only change branches after you commit your code to the current branch. 

The IDE (aka, dev env) uses individual developer credentials to connect to your data platform. These credentials should be specific to your user. They should not be super user credentials, shouldn't be the same credentials for your dbt prod env.





















### Secure your tenant





## dbt Core



## Run your dbt projects



## Use threads






























