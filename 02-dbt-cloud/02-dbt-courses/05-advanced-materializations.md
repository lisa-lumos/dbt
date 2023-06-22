# 5. Advanced materializations

## tables, views, ephemeral models
When you change the materialization of a model from table to view, in Snowflake, the old table is dropped. Because Snowflake doesn't allow a view and table to have the same name in one schema. 

When you change the materialization of a model from view to ephemeral, that previous materialization will still exist in snowflake, dbt will neither drop it, nor use it. This is because the old table/view might be used by someone else, without dbt knowing about it. By not dropping it, dbt will not break anything. If you confirm no one else if using it, you should manually drop it. 

(Refer to docs https://docs.getdbt.com/docs/build/materializations#ephemeral)
Advice: Use the ephemeral materialization for:
- very light-weight transformations that are early on in your DAG
- are only used in one or two downstream models, and
- do not need to be queried directly

## incremental models
Tactics:
- start with view
- when it takes too long to query, switch to table
- when it takes too long to build (many many minutes), switch to incremental

This example uses Snowplow events data. The instructor installed Snowplow on their website, and it sends records of page views and pings to their data warehouse. 

If you go to the developer console in chrome, click the ">>" button, and click "Snowplow", you can see the events that got collected. These events data are loaded into Snowflake in real time. 

The sources table are defined as "models/snowplow.yml":
```yml
version: 2
sources:
  - name: snowplow
    database: raw
    loaded_at_field: collector_tstamp
    freshness:
      - error_after: {count: 1, period: hour}
    tables:
      - name: events
```

To separate from two event types (page pings and page views), and see how long people stay on this webpage, they created "models/page_views.sql", with already materialized as a table:
```sql
{{
  config (materialized="table")
}}

with events as (
  select * from {{ source('snowplow', 'events') }}
),

page_views as {
  select * from events
  where event = 'page_view'
},

aggregated_page_events as (
  select
    page_view_id,
    count(*) * 10 as approx_time_on_page, -- there's an ping event every 10 secs
    min(derived_tstamp) as page_view_start,
    max(collector_tstamp) as max_collector_tstamp
  from events
  group by 1
),

joined as (
  select *
  from page_views
  left join aggregated_page_events using (page_view_id)
)

select * from joined
```

If this single model takes to long to build, they want to materialize it as incremental:
```sql
{{
  config (materialized="incremental")
}}

with events as (
  select * from {{ source('snowplow', 'events') }}
  {% if is_incremental() %} -- so it only applies to subsequent runs, not the first run. The first run skips below statement, and build new from scratch. 
  where collector_tstamp >= (
    select max(max_collector_tstamp) from {{ this }}
  ) -- {{ this }} refers to current state of the table in Snowflake
  {% endif %}
),

page_views as {
  select * from events
  where event = 'page_view'
},

aggregated_page_events as (
  select
    page_view_id,
    count(*) * 10 as approx_time_on_page, -- there's an ping event every 10 secs
    min(derived_tstamp) as page_view_start,
    max(collector_tstamp) as max_collector_tstamp
  from events
  group by 1
),

joined as (
  select *
  from page_views
  left join aggregated_page_events using (page_view_id)
)

select * from joined
```

They use the `select max(max_collector_tstamp) from {{ ref('page_views') }}` to determine which rows are new. 

The `is_incremental()` checks 4 conditions:
1. Does the corresponding object already exist in Snowflake?
2. Is the object a table?
3. Is the model is configured as `materialized="incremental"`?
4. Was the `--full-refresh` flag passed to this `dbt run`?

If the answers to these are y-y-y-n, then `is_incremental()` returns `True`. 

After modifying the model sql file, run `dbt run -m page_views` to build historical load, then use this same command for following incremental loads. 

`dbt run -m page_views --full-refresh` builds the historical load again, which uses `create or replace transient table ...` behind the scene. 

What if: a record that with a timestamp of 1pm, due its network issues, arrived at the data warehouse at 5pm only? And other records with similar timestamps arrived on time?

To try to solve this, if we use `select dateadd('day', -3, max(max_collector_tstamp)) from {{ ref('page_views') }}` to determine which rows are new, we will end up with duplicated records. We can use primary key to avoid the duplicates:
```sql
{{
  config (
    materialized="incremental",
    unique_key = 'page_view_id'
  )
}}

with events as (
  select * from {{ source('snowplow', 'events') }}
  {% if is_incremental() %} 
  where collector_tstamp >= (
    select 
      dateadd('day', -3, max(max_collector_tstamp)) 
      from {{ this }}
    ) 
  {% endif %}
),

page_views as {
  select * from events
  where event = 'page_view'
},

aggregated_page_events as (
  select
    page_view_id,
    count(*) * 10 as approx_time_on_page, 
    min(derived_tstamp) as page_view_start,
    max(collector_tstamp) as max_collector_tstamp
  from events
  group by 1
),

joined as (
  select *
  from page_views
  left join aggregated_page_events using (page_view_id)
)

select * from joined
```

Behind scene, dbt runs a merge statement against the data warehouse. 

My thoughts: if you use streams in snowflake, snowflake knows what exact DML happened against a table, so stream can catch exactly what inserts/deletes/updates changes are, without using primary key and a timestamp column. But dbt, as a 3rd-party, cannot know what exactly happened inside a table in snowflake, so it relies on primary key and watermark column to determine what is new. 

Why they used 3 days? Because the goal of incremental models is to approximate the true table in a fraction of the runtime. They performed an analysis on the arrival time of data, and figured out their org's tolerance for correctness. Once a week, they perform a full refresh run, to get the exact true table. They call it "close enough & performant". Web event data is often inaccurate - people have ad blocker, etc. 

What if one particular page view is still going on by the time we already started processing the records? In this case, the page view duration will be under-counted. Maybe it doesn't happen frequent enough for them to be concerned about it. 

What if they want to calculate window functions?
```sql
{{
  config (
    materialized="incremental",
    unique_key = 'page_view_id'
  )
}}

with events as (
  select * from {{ source('snowplow', 'events') }}
  {% if is_incremental() %} 
  where collector_tstamp >= (
    select 
      dateadd('day', -3, max(max_collector_tstamp)) 
      from {{ this }}
    ) 
  {% endif %}
),

page_views as {
  select * from events
  where event = 'page_view'
},

aggregated_page_events as (
  select
    page_view_id,
    count(*) * 10 as approx_time_on_page, 
    min(derived_tstamp) as page_view_start,
    max(collector_tstamp) as max_collector_tstamp
  from events
  group by 1
),

joined as (
  select *
  from page_views
  left join aggregated_page_events using (page_view_id)
),

indexed as (
  select 
    *, 
    
    row_number() over (
      partition by session_id 
      order by page_view_start
    ) as page_view_in_session_index,

    row_number() over (
      partition by anonymous_user_id 
      order by page_view_start
    ) as page_view_for_user_index

  from joined
)

select * from indexed
```

Run `dbt run -m page_views --full-refresh`, because we added new columns to the model. But this is a incremental model, so the window functions will only be processed for the last 3 days of data, so the data in the table will be wrong. 

They first tried: if a user has a new event, recalculate all page views for that user. It works, but slow. 

Another idea: whenever user has a new session, pull the user's most recent data only, and then perform relative calcs. If they have 1000 page view already, then the 1, 2, 3 page view in the window function, then their real val will be 1 + 1000, 2 + 1000, .... 

For truly massive datasets that are:
- Always rebuilt past 3 days. Fully ignore late arrivals
- Always replace data at the partition level
- No unique keys, because merge is too expensive compared with inserts
- Targeted look back - no way to do this, too much extra data to scan

These impose different cost-optimization problems. 

When to use incremental model:
- immutable event streams, append-only, no updates
- if need to update, have a reliable updated_at field

When not to use incremental model:
- small data
- data changes frequently
- updated unpredictably
- transformation needs other rows, in which case you should use table/view as materialization

Tradeoffs of incremental models:
- approximately correct
- more code complexity
- if you focus more on correctness, it will hurt performance gains

## Snapshots









