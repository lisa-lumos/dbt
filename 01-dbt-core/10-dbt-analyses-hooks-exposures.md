# 10. dbt analyses, hooks, and exposures
## Analyses
Ad hoc queries that do not need to be materialized, but can use the macros, model references dbt provides. 

"analyses/full_moon_no_sleep.sql":
```sql
with mart_fullmoon_reviews as (
  select * from {{ ref('mart_fullmoon_reviews') }}
)

select
  is_full_moon,
  review_sentiment,
  count(*) as reviews
from
  mart_fullmoon_reviews
group by
  is_full_moon,
  review_sentiment
order by
  is_full_moon,
  review_sentiment
```

To run this query, run `dbt compile`, then find the compiled query in the "target" folder. Copy the compiled query and run in snowflake. 

## Hooks 
SQLs that are executed at predefined times. Can be configured on the project/subfolder/model level. 

Types of hooks:
- on_run_start: executed at the start of `dbt run/seed/snapshot`
- on_run_end: executed at the end of `dbt run/seed/snapshot`
- pre-hook: executed before a model/seed/snapshot is built
- post-hook: executed after a model/seed/snapshot is built

In snowflake, create a user for reporting, assume you only give them usage privilege for the db and schema:
```sql
use role accountadmin;

create role if not exists reporter;
create user if not exists preset
  password='presetpassword123'
  login_name='preset'
  must_change_password=false
  default_warehouse='compute_wh'
  default_role='reporter'
  default_namespace='airbnb.dev'
  comment='preset user for creating reports';

grant role reporter to user preset;
grant role reporter to role accountadmin;

grant all on warehouse compute_wh to role reporter;
grant usage on database airbnb to role reporter;
grant usage on schema airbnb.dev to role reporter;
```

For this user to see all the models that are build, you can add a post hook on all models in the project, granting select on each materialized model, after dbt run for the model completes. "dbt_project.yml":
```yml
...
models:
  dbtlearn:
    +materialized: view
    +post-hook:
      - "grant select on {{ this }} to role reporter"
    dim:
...
```

After a `dbt run`, the `reporter` role can now see all the models. 

This reporter role can then be used for BI tools (such as Tableau, preset, ...) to connect to snowflake, and create dashboards. 

## Exposures
Configurations that can point to external resources, such as dashboards. They will then be included into the documentation. They live in yml files. "dashboards.yml":
```yml
version: 2

exposures:

  - name: executive_dashboard
    type: dashboard
    maturity: low
    url: https://www.my-dashboard-url.com/
    description: Executive Dashboard about Airbnb listings and hosts

    depends_on:
      - ref('dim_listings_w_hosts')
      - ref('full_moon_reviews')

    owner:
      name: dbt_learner
      email: dbt_learner@email.com
```

Generate the docs and you can see the dashboard and its meta data. It will also show up in the DAG.  
