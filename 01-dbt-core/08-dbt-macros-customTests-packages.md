# 8. Macros, custom tests and packages
Macros: Jinja templates created in the macros folder. Use them in model definitions and tests. 

dbt has many built-in macros. 

## Macros for singular tests
In "macros" folder, create a file "macros/no_nulls_in_cols.sql":
```sql
{% macro no_nulls_in_cols(model) %} -- the function takes a model
  select 
    * 
  from 
    {{ model }} 
  where
    {% for col in adapter.get_columns_in_relation(model) -%} -- adapter.get_columns_in_relation is a dbt built-in functionality. "-" at the end means trim off following white spaces, to get a one-line expression
    {{ col.column }} is null or -- if col1 is null or col2 is null or col3 is null or... (loop over all col names)
    {% endfor %}
    false -- to match the last/redundant "or" in the loop
{% endmacro %}
```
Refer to Jinja docs for syntax. 

In the "tests" folder, create a file "tests/no_nulls_in_dim_listings.sql" to use this macro:
```sql
{{ 
  no_nulls_in_columns(
    ref('dim_listings_cleansed')
  ) 
}}
```

Run `dbt compile` first to make sure things are correct, then `dbt test --select dim_listings_cleansed` to run all tests related to this model. Results show all tests passed. 

## Macros for generic tests
Custom generic tests also live in the "macros" folder. Create a new file "macros/positive_val.sql":
```sql
{% test positive_val(model, column_name) %}
select
  *
from
  {{ model }}
where
  {{ column_name }} < 1
{% endtest %}
```

Then in the "models/schema.yml", add 3 new lines at the bottom, so it becomes:
```yml
version: 2

models: 
  - name: dim_listings_cleansed # model name

    columns: 

    ...
    
    - name: minimum_nights # col name
      tests:
        - positive_val
```

Run `dbt test --select dim_listings_cleansed` and see test results. 

### 3rd-party packages
`hub.getdbt.com`, and other websites to find packages, such as great expectations. 

To install the package called dbt_utils, go to `https://hub.getdbt.com/dbt-labs/dbt_utils/latest/`, and follow instructions. 

In the project folder, create a file "packages.yml" to add below references:
```yml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1
```

Run `dbt deps` to install the package:
```console
(venv) (base) lisa@mac16 dbtlearn % dbt deps
20:33:39  Running with dbt=1.5.1
20:33:40  Installing dbt-labs/dbt_utils
20:33:40  Installed from version 1.1.1
20:33:40  Up to date!
```

In this package, there is a "generate_surrogate_key" macro, which can be used to generate a primary key by combining different cols. Our module "fct_reviews" doesn't have a primary key, so can use this functionality. 

Use the macro like this `dbt_utils.generate_surrogate_key(col1, col2, ...)`, so "models/fct/fct_reviews.sql" becomes:
```sql
{{
  config(
    materialized = 'incremental',
    on_schema_change='fail'
  )
}}

with src_reviews as (
  select 
    * 
  from 
    {{ ref('src_reviews') }}
)

select 
  {{ dbt_utils.generate_surrogate_key(
    [
      'listing_id', 
      'review_date', 
      'reviewer_name', 
      'review_text'
    ]) }} as review_id,
  * 
from 
  src_reviews
where 
  review_text is not null

{% if is_incremental() %}
  and 
  review_date > (select max(review_date) from {{ this }})
  -- can hold very complex conditions
{% endif %}
```

Because this module is incremental, and adding a new col changes the schema, so run the model directly will fail. So we will need a full refresh. Run `dbt run --full-refresh --select fct_reviews` to refresh this model in Snowflake. 

See the review_id col in this table:
```
REVIEW_ID                         ...
434c90a19a01e8dbec80c9a55987170e  ...
2e07af9058887cf97f788ad2fc302db6  ...
...                               ...
```
