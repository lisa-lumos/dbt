# 3. dbt models
Models: 
- Are the basic building block of your business logic, and a dbt project. 
- Can be thought of as sql definitions that can materialize tables/views. 
- Live in sql files in the "models" folder in a dbt project
- They are more than sql select statements - they can reference each other, and use templates and macros. 

CTEs are temp named result set, which help us to write readable and maintainable code. 

Given 3 tables sitting in the raw layer now, the first cleansing step is to create 3 views in the staging layer, corresponding to these 3 tables, with renamed cols, etc. 

Construct first query as:
```sql
with raw_listings as (
 select *
 from airbnb.raw.raw_listings
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
from
  raw_listings
```

First, test it in Snowflake directly to make sure it works. 

Next, put in as a dbt model in the dbt project. Inside the "models" folder, you can have models in subfolders, or keep them at the top level. Create a new subfolder "src", and create a file "src_listings.sql" inside it. Paste the above query inside it (note that the query shouldn't end with semicolon). This instructs dbt that we want to create a new view "raw_listings", with the given definition. This can also be a table, but views are default. 

`dbt run` command will instruct dbt to go through your models and tests and everything, and look at the changes in your project and apply them. 

```console
(venv) (base) lisa@mac16 dbtlearn % dbt run  
22:46:18  Running with dbt=1.5.1
22:46:18  Found 1 model, 0 tests, 0 snapshots, 0 analyses, 321 macros, 0 operations, 0 seed files, 0 sources, 0 exposures, 0 metrics, 0 groups
22:46:18  
22:46:20  Concurrency: 1 threads (target='dev')
22:46:20  
22:46:20  1 of 1 START sql view model DEV.src_listings ................................... [RUN]
22:46:21  1 of 1 OK created sql view model DEV.src_listings .............................. [SUCCESS 1 in 0.89s]
22:46:21  
22:46:21  Finished running 1 view model in 0 hours 0 minutes and 2.85 seconds (2.85s).
22:46:21  
22:46:21  Completed successfully
22:46:21  
22:46:21  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

Now the view "AIRBNB.DEV.SRC_LISTINGS" is created in snowflake by dbt. 

Do similar things to the other two raw tables. 

"models/src/src_reviews.sql":
```sql
with raw_reviews as (
  select *
  from airbnb.raw.raw_reviews
)

select
  listing_id,
  date as review_date,
  reviewer_name,
  comments as review_text,
  sentiment as review_sentiment
from raw_reviews
```

"models/src/src_hosts.sql":
```sql
with raw_hosts as (
  select *
  from airbnb.raw.raw_hosts
)

select
  id as host_id,
  name as host_name,
  is_superhost,
  created_at,
  updated_at
from raw_hosts
```

And do `dbt run` to build all 3 views:
```console
(venv) (base) lisa@mac16 dbtlearn % dbt run
22:56:21  Running with dbt=1.5.1
22:56:22  Found 3 models, 0 tests, 0 snapshots, 0 analyses, 321 macros, 0 operations, 0 seed files, 0 sources, 0 exposures, 0 metrics, 0 groups
22:56:22  
22:56:24  Concurrency: 1 threads (target='dev')
22:56:24  
22:56:24  1 of 3 START sql view model DEV.src_hosts ...................................... [RUN]
22:56:24  1 of 3 OK created sql view model DEV.src_hosts ................................. [SUCCESS 1 in 0.90s]
22:56:24  2 of 3 START sql view model DEV.src_listings ................................... [RUN]
22:56:25  2 of 3 OK created sql view model DEV.src_listings .............................. [SUCCESS 1 in 1.04s]
22:56:25  3 of 3 START sql view model DEV.src_reviews .................................... [RUN]
22:56:26  3 of 3 OK created sql view model DEV.src_reviews ............................... [SUCCESS 1 in 0.85s]
22:56:26  
22:56:26  Finished running 3 view models in 0 hours 0 minutes and 4.76 seconds (4.76s).
22:56:26  
22:56:26  Completed successfully
22:56:26  
22:56:26  Done. PASS=3 WARN=0 ERROR=0 SKIP=0 TOTAL=3
```
