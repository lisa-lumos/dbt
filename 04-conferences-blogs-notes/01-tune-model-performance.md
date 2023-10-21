# 1. How dbt Labs tunes model performance and optimizes cloud data platform costs with dbt
You can optimize query performance without refactoring the dbt model, you simply need to pick the right warehouse size for that model, based on its past performance. The dbt model responsible for "the performance of dbt models" picks the right warehouse size for you, automatically, at model level. 

What is used:
- Snowflake query tags
- dbt models based on snowflake views
- dbt configs

dbt can put info into a snowflake query's tag, for each query dbt runs. This tag can be used for later analysis on query performance, etc. 

Set this up as early as possible, so if you need to use it in the future, the data is already there. 

```mermaid
%%{ init: { 'flowchart': { 'curve': 'basis' } } }%%
flowchart LR

  sc_1("snowflake.account_usage.query_history")
  sc_2("my_db.information_schema.tables")
  model_1("stg_query_history")
  model_2("stg_tables")
  model_3("warehouse_recommendations")

  sc_1 --> model_1
  sc_2 --> model_2
  model_1 & model_2 --> model_3
 
  class model_1,model_2,model_3 modelClass;
  classDef modelClass fill:#ffffff, stroke:#808080, stroke-width:2px;
 
  class sc_1,sc_2 sourceClass;
  classDef sourceClass fill:#ffffff, stroke:#808080, stroke-width:2px;
 
  linkStyle default stroke-width:2px,fill:none,stroke:black;
```

Snowflake metadata views provide data on table size, query performance, etc. This information, together with the JSON tags on the queries, can be parsed in a dbt model `stg_query_history`, which relates dbt model names to snowflake queries used to create these models. `warehouse_recommendations` model aggregates query statistics for models, to provide recommendations. 

They are "dbt models" about "the performance of dbt models". 

Defined compute recommendations:
- Query efficiency is measured by spillage to local/remote storage
- Additional prescriptive recommendations based on average model execution time, table size in terms of bytes/rows. 

dbt configs example:
```sql
{{
    config(
        snowflake_warehouse = 'prod_wh_xl'
    )
}}
```
The results from the `warehouse_recommendations` model get pasted as an argument into the above configuration, which happens at the model level. When dbt invokes that model, it issues a `use warehouse ...` command for that session, for that model only. 

A dashboard can be built up on this work, to monitor effectiveness. For the models that resizing warehouse doesn't work, we can then look into refactoring them. 

In dbt Labs experiment, without any model refactoring, this method decreased 45% of run time, and reduced annual cost of $22k, because the jobs run faster, despite using a larger warehouse. 

This method can also include flagging mechanism for when a model's materialization strategy needs to be changed, such as from "table" to "incremental". 

## Appendix
The example "set_query_tag.sql" file, to create tags for model runs (copied form Elize Papineau's GitHub):
```sql
{%- macro set_query_tag() -%}

  {# These are built in dbt Cloud environment variables you can leverage to better understand your runs usage data #}
  {%- set dbt_job_id = env_var('DBT_CLOUD_JOB_ID', 'not set') -%}
  {%- set dbt_run_id = env_var('DBT_CLOUD_RUN_ID', 'not set') -%}
  {%- set dbt_run_reason = env_var('DBT_CLOUD_RUN_REASON', 'development_and_testing') -%}

  {# These are built in to dbt Core #}
  {%- set dbt_project_name = project_name -%}
  {%- set dbt_user_name = target.user -%}
  {%- set dbt_model_name = model.name -%}
  {%- set dbt_materialization_type = model.config.materialized -%}
  {%- set dbt_environment_name = target.name -%}

  {%- if dbt_model_name -%}
    
    {%- set new_query_tag = '{"dbt_environment_name": "%s", "dbt_job_id": "%s", "dbt_run_id": "%s", "dbt_run_reason": "%s", "dbt_project_name": "%s", "dbt_user_name": "%s", "dbt_model_name": "%s", "dbt_materialization_type": "%s"}'
      | format(
                dbt_environment_name,
                dbt_job_id,
                dbt_run_id, 
                dbt_run_reason,
                dbt_project_name,
                dbt_user_name,
                dbt_model_name,
                dbt_materialization_type
    ) -%}
    {%- set original_query_tag = get_current_query_tag() -%}
    {{ log("Setting query_tag to '" ~ new_query_tag ~ "'. Will reset to '" ~ original_query_tag ~ "' after materialization.") }}
    {%- do run_query("alter session set query_tag = '{}'".format(new_query_tag)) -%}
    {{ return(original_query_tag)}}
  
  {%- endif -%}
  
  {{ return(none) }}

{%- endmacro -%}
```