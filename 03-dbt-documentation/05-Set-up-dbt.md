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

#### UI
dbt Editor Command Palette: Displays text editing actions, and their associated keyboard shortcuts. Can be accessed by:
- press F1, or,
- right-click in the text editing area, and select Command Palette.

CSV Preview console tab: Displays the data from your CSV file in a table, syncs as you edit the seed file.

Preview button: Runs the SQL in the active file editor, including unsaved edits, and sends the results to the "Results" tab.

Compile button: compiles the SQL code from the active File Editor, including unsaved edits, and outputs it to the "Compiled Code" tab.

Editor tab menu: Right-click any tab to access the options, such as close all/other files, copy file name, ...

Global Command Palette: Provides shortcuts to interact with the IDE, such as git actions, specialized dbt commands, compile, and preview actions, etc. To open the menu, use Command-P or Control-P.

#### Lint and format
skipped. 

#### Tips and tricks
Select/edit multiple lines: Hold Option on macOS, or Hold Alt on Windows.

Reveal a list of dbt functions: Enter __ in the editor.

Add a block comment: `Command + Option + /` on macOS, or `Control + Alt + /` on Windows, on the selected code. 

Use the `dbt_codegen` package, to help you generate YML files for your models/sources.

Use your folder structure as your primary selector method. `dbt build --select marts.marketing` is simpler/resilient than relying on tagging.

Think about jobs in terms of build cadences/dependencies and SLAs. Run models that have hourly, daily, or weekly build cadences/dependencies together.

Use incremental_strategy in your incremental model config, to implement the most effective behavior, depending on the volume of your data, and reliability of your unique keys.

Set `vars` in your "dbt_project.yml" to define global defaults for certain conditions, which you can then override using the `--vars` flag in your commands.

Instead of relying on post-hooks, use the grants config to apply permission grants in the warehouse resiliently.

Use target.name based on what env you're using. For example, to build into a single dev schema while developing, but use multiple schemas in production.

### Secure your tenant
The setup of a Snowflake AWS PrivateLink endpoint, in the dbt Cloud multi-tenant environment.

Organizations can configure IP restrictions, with these dbt Cloud Enterprise tiers:
- Business Critical
- Virtual Private

### Billing
You pay for the num of seats (Developer/Read-Only/IT) you have, and the amount of usage (num of successful models built/run in prod) each month. Seats are billed primarily on the purchased num of Developer licenses. 

Every plan automatically sends email alerts when 75%, 90%, and 100% of usage estimates have been reached. 

## dbt Core
dbt Core is an open-source tool, which enables data teams to transform data using analytics engineering best practices. You can install dbt locally in your environment, and use it on the command line. It communicates with databases through adapters.

### About the CLI
To use the CLI, your workflow looks like:
- Build your dbt project in a code editor
- Run your project from the command line

### dbt Core environments
dbt maintain prod and dev envs, through the use of targets within a profile.

A typical profile, when using dbt locally, will have a target named dev as the default. Once you are confident in your changes in dev, you can deploy the code to prod, by running your dbt project with a prod target.

Targets offer the flexibility to decide how to implement your separate envs - whether you want to use separate schemas/databases/clusters. 

We recommend using different schemas within one db, to separate your envs. This is the easiest to set up, and is the most cost-effective solution, in a modern cloud-based data stack. In practice, this means that most of the configs will be same across targets, except for the schema, and user credentials.

If you have multiple developers, recommend for each user to have their own dev env, with target schema named by user name, such as "dbt_lisa". User credentials should also differ across targets, so that each dbt user is using their own data warehouse user.

### Install dbt Core
Recommend to use pip to install dbt: `pip install dbt-<adapterName>`. 

To upgrade a specific adapter plugin: `pip install --upgrade dbt-<adapterName>`

### Connect data platform
To use dbt from the CLI, you need a "profiles.yml" file, which contains the connection details for your data platform. 

When you run dbt from the CLI, it reads your "dbt_project.yml" file in your project folder, to find the profile name, and then looks for a profile with the same name in your "profiles.yml" file. 

#### About "profiles.yml" file
If you're using dbt Cloud, you connect to your data platform directly, using GUI, and don't need the "profiles.yml" file.

You can set default values of global configs, for all projects that you run on your local machine. 

#### Connection profiles in "profiles.yml"
dbt will search the current working directory for the "profiles.yml" file, and will default to the` ~/.dbt/` directory if not found.

This file generally lives outside of your dbt project, to avoid sensitive credentials being checked in to version control. But it can be safely checked in using environment variables to load sensitive credentials.

In "profiles.yml" file, you can store as many profiles as you need. Typically, you would have one profile for each warehouse you use. Most organizations only have one profile.

A profile consists of "targets", and a specified "default target". Each target specifies the type of warehouse you are connecting to, the credentials to connect to it, and some dbt-specific configs. You may need to surround your password in quotes, if it contains special characters.
- Profile name: Recommend to use the name of your organization.
- `target`: The default target for your dbt project. Must be one of the targets you define in your profile. Commonly it is set to `dev`.
- schema: The default schema that dbt will build objects in.
- threads: The num of threads the dbt project will run on.

Run `dbt debug` from within a dbt project, to test your connection.

You may also have a `prod` target within your profile, which creates the objects in your prod schema. However, production runs are often executed on a schedule, we recommend deploying your dbt project to a separate machine, other than your local machine. Most dbt users only have a `dev` target in their profile on their local machine, with schema named "dbt_userName".

If you do have multiple targets in your profile, and want to use a target other than the default, you can do this using the `--target` option when issuing a dbt command.

The schema used for production: recommend name: `analytics`.

There's no need to create your target schema beforehand - dbt will check if the schema already exists when it runs, and create it if it doesn't.

While the target schema represents the dbt default schema, you can have your models in separate schemas, by using "custom schemas".

The number of threads represents the max num of paths through the DAG dbt may work on at once. Increasing the num of threads can minimize the run time of your project. The default value is 4 threads.

The location dir for "profiles.yml" has the following precedence:
- `--profiles-dir` option in dbt run
- `DBT_PROFILES_DIR` environment variable
- current working dir
- `~/.dbt/` dir

Credentials can be placed directly into the profiles.yml file, or loaded from environment variables. Using environment variables is especially useful for prod deployments of dbt.

## Run your dbt projects
Nothing new here. Skipped. 

## Use threads
If you specify "threads: 1", dbt will start building only one model, and finish it, before moving onto the next. Specifying "threads: 8" means that dbt will work on up to 8 models at once, without violating dependencies - the actual number of models it can work on will likely be constrained by the available paths through the dependency graph.

Increasing the number of threads increases the load on your warehouse, which may impact other tools in your data stack, that uses the same compute resources as dbt. 

The number of concurrent queries your data platform will allow you to run, may be a limiting factor in how many models can be actively built - some models may queue, while waiting for an available query slot.

We recommend setting this to 4, to start with. Recommend to test different values to find the best num of threads for your project.

In dbt Core, you define the number of threads in your "profiles.yml" file; in dbt Cloud, you can define it in job definition, and dbt Cloud development credentials under your profile.
