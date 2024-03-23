# 4. dbt materializations
4 types of materializations:
- View. Is default. Lightweight. Not good for reuse. 
- Table. Good for reuse. 
- Incremental (table appends). Appends to tables, good for fact tables. Do not update historical records. 
- Ephemeral (CTEs). Not materialized in any way, just an alias. 

In the "models" folder, create a new folder "dim". Inside it, create a new file "models/dim/dim_listings_cleansed.sql":
```sql
with src_listings as (
  select *
  from {{ ref('src_listings') }}
)

select
  listing_id,
  listing_name,
  room_type,
  case
    when minimum_nights = 0 then 1
    else minimum_nights
  end as minimum_nights, -- change all 0s to 1s
  host_id,
  replace(price_str, '$') :: number(10,2) as price, -- rmv $ sign in the string, and convert to number
  created_at,
  updated_at
from src_listings
```

Note the reference used in it. dbt heavily relies on Jinja. 

And another model "models/dim/dim_hosts_cleansed.sql":
```sql
with src_hosts as (
  select *
  from {{ ref('src_hosts') }}
)

select
  host_id,
  nvl(host_name, 'anonymous') as host_name, -- replace nulls with anonymous
  is_superhost,
  created_at,
  updated_at
from src_hosts
```

`dbt run` now will create all 5 models from scratch. 

The "dbt_project.yml" file in the project folder is where you can set configurations, such as this at the end of the file:
```yml
models:
  dbtlearn:
    +materialized: view
    dim:
      +materialized: table
```
Which specifies that all models, by default, should be materialized as views. While all models in the "dim" folder should be materialized as tables. 

Now run `dbt run`, and we will see 3 views and 2 tables in Snowflake. 

Inside the "models" folder, create a "fct" folder to store the fact models. 

Add model "models/fct/fct_reviews.sql":
```sql
{{
  config(
    materialized = 'incremental',
    on_schema_change='fail'
  )
}}

with src_reviews as (
  select * 
  from  {{ ref('src_reviews') }}
)

select * 
from src_reviews
where review_text is not null

{% if is_incremental() %}
  and 
  review_date > (select max(review_date) from {{ this }})
  -- can hold very complex conditions
{% endif %}
```

Note that this model is incremental, and the run will fail if the upstream schema changes. The incremental condition is specified at the end of the file. 

Now run `dbt run`, and obtain the 3 views and 3 tables in snowflake. 

To simulate new recording being added to raw data, manually execute below in snowflake:
```sql
insert into airbnb.raw.raw_reviews
values (
  3176, 
  current_timestamp(), 
  'Zoltan', 
  'excellent stay!', 
  'positive'
)
;
```

Execute `dbt run` again: 
```console
(venv) (base) lisa@mac16 dbtlearn % dbt run
23:57:41  Running with dbt=1.5.1
23:57:41  Found 6 models, 0 tests, 0 snapshots, 0 analyses, 321 macros, 0 operations, 0 seed files, 0 sources, 0 exposures, 0 metrics, 0 groups
23:57:41  
23:57:43  Concurrency: 1 threads (target='dev')
23:57:43  
23:57:43  1 of 6 START sql view model DEV.src_hosts ...................................... [RUN]
23:57:44  1 of 6 OK created sql view model DEV.src_hosts ................................. [SUCCESS 1 in 0.71s]
23:57:44  2 of 6 START sql view model DEV.src_listings ................................... [RUN]
23:57:45  2 of 6 OK created sql view model DEV.src_listings .............................. [SUCCESS 1 in 1.04s]
23:57:45  3 of 6 START sql view model DEV.src_reviews .................................... [RUN]
23:57:46  3 of 6 OK created sql view model DEV.src_reviews ............................... [SUCCESS 1 in 1.03s]
23:57:46  4 of 6 START sql table model DEV.dim_hosts_cleansed ............................ [RUN]
23:57:48  4 of 6 OK created sql table model DEV.dim_hosts_cleansed ....................... [SUCCESS 1 in 1.68s]
23:57:48  5 of 6 START sql table model DEV.dim_listings_cleansed ......................... [RUN]
23:57:49  5 of 6 OK created sql table model DEV.dim_listings_cleansed .................... [SUCCESS 1 in 1.47s]
23:57:49  6 of 6 START sql incremental model DEV.fct_reviews ............................. [RUN]
23:57:52  6 of 6 OK created sql incremental model DEV.fct_reviews ........................ [SUCCESS 1 in 2.92s]
23:57:52  
23:57:52  Finished running 3 view models, 2 table models, 1 incremental model in 0 hours 0 minutes and 10.77 seconds (10.77s).
23:57:52  
23:57:52  Completed successfully
23:57:52  
23:57:52  Done. PASS=6 WARN=0 ERROR=0 SKIP=0 TOTAL=6

```

And see the new record in `fct_reviews` table. 

If you schema changes, to rebuild the whole table, run `dbt run --full-refresh`

Inside the dim folder, create "models/dim/dim_listings_w_hosts.sql":
```sql
with
l as (
  select *
  from {{ ref('dim_listings_cleansed') }}
),

h as (
  select *
  from {{ ref('dim_hosts_cleansed') }}
)

select
  l.listing_id,
  l.listing_name,
  l.room_type,
  l.minimum_nights,
  l.price,
  l.host_id,
  h.host_name,
  h.is_superhost as host_is_superhost,
  l.created_at,
  greatest(l.updated_at, h.updated_at) as updated_at
from l 
left join h 
on h.host_id = l.host_id
```

Now do `dbt run`, and see the new fact table. 

Notice that all models in the "src" folder doesn't need to be materialized as views/tables - they can be ephemeral. So Modify the last block of "dbt_project.yml" to:
```yml
models:
  dbtlearn:
    +materialized: view
    dim:
      +materialized: table
    src:
      +materialized: ephemeral
```

Run all the models:
```console
(venv) (base) lisa@mac16 dbtlearn % dbt run
00:48:59  Running with dbt=1.5.1
00:48:59  Unable to do partial parsing because a project config has changed
00:48:59  Found 7 models, 0 tests, 0 snapshots, 0 analyses, 321 macros, 0 operations, 0 seed files, 0 sources, 0 exposures, 0 metrics, 0 groups
00:48:59  
00:49:01  Concurrency: 1 threads (target='dev')
00:49:01  
00:49:01  1 of 4 START sql table model DEV.dim_hosts_cleansed ............................ [RUN]
00:49:04  1 of 4 OK created sql table model DEV.dim_hosts_cleansed ....................... [SUCCESS 1 in 2.52s]
00:49:04  2 of 4 START sql table model DEV.dim_listings_cleansed ......................... [RUN]
00:49:06  2 of 4 OK created sql table model DEV.dim_listings_cleansed .................... [SUCCESS 1 in 1.80s]
00:49:06  3 of 4 START sql incremental model DEV.fct_reviews ............................. [RUN]
00:49:08  3 of 4 OK created sql incremental model DEV.fct_reviews ........................ [SUCCESS 0 in 2.70s]
00:49:08  4 of 4 START sql table model DEV.dim_listings_w_hosts .......................... [RUN]
00:49:10  4 of 4 OK created sql table model DEV.dim_listings_w_hosts ..................... [SUCCESS 1 in 1.77s]
00:49:10  
00:49:10  Finished running 3 table models, 1 incremental model in 0 hours 0 minutes and 10.84 seconds (10.84s).
00:49:10  
00:49:10  Completed successfully
00:49:10  
00:49:10  Done. PASS=4 WARN=0 ERROR=0 SKIP=0 TOTAL=4

```

You will still have the 3 "src" views in snowflake, because dbt does not explicitly drop them. You need to drop them manually:
```sql
drop view airbnb.dev.src_hosts;
drop view airbnb.dev.src_listings;
drop view airbnb.dev.src_reviews;
```

`dbtlearn/target/run/dbtlearn/models` folder contains the actual commands that were run against snowflake. From there, you can see how CTEs are used to create the dim tables. This can also be useful for debugging. 

Prepending below code to a model specifies that the model needs to be materialized as a view: 
```sql
{{
  config(materialized = 'view')
}}
```

Do this to both "models/dim/dim_listings_cleansed.sql" and "models/dim/dim_hosts_cleansed". Run all the models, and see two views and two tables in snowflake. 
