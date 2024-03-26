# dbt seeds and sources
Seeds: local files that dbt uploads to the data warehouse. Seeds live in the "seeds" folder in a dbt project. 

Sources: an abstraction layer on top of your input tables. Source freshness can be checked automatically. 

Grab this csv file from S3 bucket into the "seeds" folder:
```console
(venv) (base) lisa@mac16 dbtlearn % curl https://dbtlearn.s3.us-east-2.amazonaws.com/seed_full_moon_dates.csv -o seeds/seed_full_moon_dates.csv
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3007  100  3007    0     0   5067      0 --:--:-- --:--:-- --:--:--  5087
```

`dbt seed` command uploads this csv file to snowflake:
```console
(venv) (base) lisa@mac16 dbtlearn % dbt seed
00:54:49  Running with dbt=1.5.1
00:54:49  Found 7 models, 0 tests, 0 snapshots, 0 analyses, 321 macros, 0 operations, 1 seed file, 0 sources, 0 exposures, 0 metrics, 0 groups
00:54:49  
00:54:52  Concurrency: 1 threads (target='dev')
00:54:52  
00:54:52  1 of 1 START seed file DEV.seed_full_moon_dates ................................ [RUN]
00:54:54  1 of 1 OK loaded seed file DEV.seed_full_moon_dates ............................ [INSERT 272 in 2.68s]
00:54:54  
00:54:54  Finished running 1 seed in 0 hours 0 minutes and 5.12 seconds (5.12s).
00:54:54  
00:54:54  Completed successfully
00:54:54  
00:54:54  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

Create a "mart" folder inside the "models" folder. This folder will be accessed by BI tools. Create a "models/mart/full_moon_reviews.sql":
```sql
{{ 
  config(materialized = 'table') 
}}

with fct_reviews as (
  select * 
  from {{ ref('fct_reviews') }}
),

full_moon_dates as (
  select * 
  from {{ ref('seed_full_moon_dates') }} -- refer to seeds directly, like a model
)

select
  r.*,
  case
    when fm.full_moon_date is null then 'not full moon'
    else 'full moon'
  end as is_full_moon
from fct_reviews r
left join full_moon_dates fm
  on to_date(r.review_date) = dateadd(day, 1, fm.full_moon_date)
```

Sources can be defined in yaml files in the "models" folder. Create a "models/sources.yml":
```yml
version: 2

sources:
  - name: airbnb
    schema: raw
    tables:
      - name: listings
        identifier: raw_listings
      - name: hosts
        identifier: raw_hosts
      - name: reviews
        identifier: raw_reviews
```

With this, you can then name your raw tables as "source tables", and use their new names in model definitions, such as `{{ source('airbnb', 'listings')}}` to refer to the `airbnb.raw.raw_listings` table. In this way, if later these source tables move to other places, you can just update this file in one place, and all references of them from the models will all be updated.

Rewrite the 3 models in "src" folder, "models/src/src_hosts.sql":
```sql
with raw_hosts as (
  select *
  from {{ source('airbnb', 'hosts')}} -- airbnb.raw.raw_hosts
)

select
  id as host_id,
  name as host_name,
  is_superhost,
  created_at,
  updated_at
from raw_hosts
```

"models/src/src_listings.sql":
```sql
with raw_listings as (
  select *
  from {{ source('airbnb', 'listings')}} -- airbnb.raw.raw_listings
)

select
  id as listing_id,
  name as listing_name,
  listing_url,
  room_type,
  minimum_nights,
  host_id,
  price as price_str,
  created_at,
  updated_at
from raw_listings
```

"models/src/src_reviews.sql":
```sql
with raw_reviews as (
  select *
  from {{ source('airbnb', 'reviews')}} -- airbnb.raw.raw_reviews
)
select
  listing_id,
  date as review_date,
  reviewer_name,
  comments as review_text,
  sentiment as review_sentiment
from raw_reviews
```

Next, to check whether all the templates etc makes sense, run `dbt compile`:
```console
(venv) (base) lisa@mac16 dbtlearn % dbt compile
03:15:00  Running with dbt=1.5.1
03:15:00  Found 8 models, 0 tests, 0 snapshots, 0 analyses, 321 macros, 0 operations, 1 seed file, 3 sources, 0 exposures, 0 metrics, 0 groups
03:15:00  
03:15:01  Concurrency: 1 threads (target='dev')
03:15:01  
```

Source freshness: In a production setting, you want some monitoring in place, to check if everything works right. For example, you may want to monitor the last timestamp of the ingested data, and if there's a small delay, give a warning, and if there's a big delay, give an error. 

In "models/sources.yml", you can define source freshness constraints, such as for the reviews source table: 
```yml
      - name: reviews
        identifier: raw_reviews
        loaded_at_field: date
        freshness:
          warn_after: {count: 1, period: hour}
          error_after: {count: 24, period: hour}
```
This means if the date field contains no value that is within 1hr fresh, it will give a warning, and if this field has no value that is within 24hr fresh, it will give an error. 

Run `dbt source freshness` to check the defined freshness constraints:
```console
(venv) (base) lisa@mac16 dbtlearn % dbt source freshness
03:26:19  Running with dbt=1.5.1
03:26:20  Found 8 models, 0 tests, 0 snapshots, 0 analyses, 321 macros, 0 operations, 1 seed file, 3 sources, 0 exposures, 0 metrics, 0 groups
03:26:20  
03:26:21  Concurrency: 1 threads (target='dev')
03:26:21  
03:26:21  1 of 1 START freshness of airbnb.reviews ....................................... [RUN]
03:26:23  1 of 1 ERROR STALE freshness of airbnb.reviews ................................. [ERROR STALE in 1.78s]
03:26:23  
03:26:23  Done.
```
