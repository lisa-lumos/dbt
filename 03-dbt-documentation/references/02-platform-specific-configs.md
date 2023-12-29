# 2. Platform-specific configs
## Snowflake configs
By default, all Snowflake tables created by dbt are transient.

A whole folder/package can be configured to be transient (or not), by adding a line to the dbt_project.yml file. 

A specific model can be configured to be transient, by setting the transient model config to true.

Query tags are a Snowflake parameter that can be quite useful later on, when searching in the QUERY_HISTORY view.

dbt supports setting a default query tag, for the duration of its Snowflake connections in your profile. You can set more precise values (and override the default), for subsets of models, by setting a `query_tag` model config, or by overriding the default `set_query_tag` macro. 

Query tags are set at the session level. At the start of each model materialization, if the model has a custom query_tag configured, dbt will run `alter session set query_tag` to set the new value. At the end of the materialization, dbt will run another alter statement to reset the tag to its default value. 

As such, build failures midway through a materialization, may result in subsequent queries running with an incorrect tag.

By default, dbt uses a merge statement on Snowflake to refresh incremental tables. It can be configured to delete+insert for a model. 

dbt supports table clustering on Snowflake, for incremental models. 

The default warehouse that dbt uses can be configured in your Profile. To override the warehouse for specific models (or groups of models), use the `snowflake_warehouse` model config.

When the `copy_grants` config is set to true, dbt will add the copy grants DDL qualifier, when rebuilding tables and views. The default value is false.

To create a Snowflake secure view, use the `secure` config for view models.

Beginning in dbt version 1.3, incremental table merges for Snowflake prefer to utilize a view, rather than a temporary table. To avoid the database write step that a temporary table would initiate, and save compile time.

However, some situations remain where a temporary table would achieve results faster or more safely. dbt v1.4 adds the `tmp_relation_type` config to allow you to opt in to temporary tables for incremental builds.

dbt partially support dynamic tables. 
