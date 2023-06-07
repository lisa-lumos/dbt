# dbt

## dbt Overview
dbt transforms data in the DWH with SQL select statements. It will deploy your analytics code following software engineering best practices, like modularity, portability, CICD, testing and documentation. You will write your code an compile it to sql and execute it, the transformations are version controlled. It allow you to create different environments like dev and prod, and easily switch between them. In terms of performance, dbt will take your models, understand the dependencies between them, and will create a dependency order and parallelize the way your models are built. 

## Use case and Input data model Overview
Suppose you are a analytics engineer in Airbnb that is responsible for all the data flow in Berlin, Germany and Europe. You need to import your data into a data warehouse, cleanse and expose the data to a BI tool. You will also need to write test, automation and documentation. Our data source is Airbnb's data sharing site `insideairbnb.com/berlin/`. 

The requirements: 
- Modeling changes are easy to follow and revert
- Explicit dependencies between models, so the framework knows in which order to execute different steps in the pipeline; also these dependencies need to be easy to explore and overview
- Data quality tests
- Error reporting
- Track history of dimension tables, for new records, and slowly changing dimensions
- Easy-to-access documentation

## Snowflake & dbt setup
Create db, role, user, warehouse, and grant privileges for objects in snowflake for dbt: 
```sql
use role accountadmin;

create database if not exists airbnb;
create schema if not exists airbnb.raw;

create warehouse if not exists compute_wh;

create role if not exists transform;
create user if not exists dbt
  password='...' -- supply your pwd here
  login_name='dbt'
  must_change_password=false
  default_warehouse='compute_wh'
  default_role='transform'
  default_namespace='airbnb.raw'
  comment='dbt user for data transformation';

grant role transform to role accountadmin;
grant role transform to user dbt;

grant all on database airbnb to role transform;
grant all on all schemas in database airbnb to role transform;
grant all on future schemas in database airbnb to role transform;
grant all on all tables in schema airbnb.raw to role transform;
grant all on future tables in schema airbnb.raw to role transform;

grant all on warehouse compute_wh to role transform; 
```

Create tables in snowflake and import data from a S3 public bucket directly:
```sql
use warehouse compute_wh;
use database airbnb;
use schema raw;

-- create our three tables and import the data from s3
create or replace table 
  raw_listings(
    id integer,
    listing_url string,
    name string,
    room_type string,
    minimum_nights integer,
    host_id integer,
    price string,
    created_at datetime,
    updated_at datetime
  );

copy into 
  raw_listings (
    id,
    listing_url,
    name,
    room_type,
    minimum_nights,
    host_id,
    price,
    created_at,
    updated_at
  )
from 's3://dbtlearn/listings.csv'
file_format = (type = 'csv' skip_header = 1 field_optionally_enclosed_by = '"');

create or replace table 
  raw_reviews(
    listing_id integer,
    date datetime,
    reviewer_name string,
    comments string,
    sentiment string
  );

copy into 
  raw_reviews (
    listing_id, 
    date, 
    reviewer_name, 
    comments, 
    sentiment
  )
from 's3://dbtlearn/reviews.csv'
file_format = (type = 'csv' skip_header = 1 field_optionally_enclosed_by = '"');

create or replace table 
  raw_hosts(
    id integer,
    name string,
    is_superhost string,
    created_at datetime,
    updated_at datetime
  );

copy into 
  raw_hosts (
    id, 
    name, 
    is_superhost, 
    created_at, 
    updated_at
  )
from 's3://dbtlearn/hosts.csv'
file_format = (type = 'csv' skip_header = 1 field_optionally_enclosed_by = '"');
```

Install Python 3.11 from official website. 

Then setup virtual env, and install dbt:
```console
(base) lisa@mac16 ~ % /usr/local/bin/python3 -m venv /Users/lisa/Desktop/dbt/01-dbt-core/code/venv # create a venv in the "venv" folder
(base) lisa@mac16 % cd /Users/lisa/Desktop/dbt/01-dbt-core/code/venv
(base) lisa@mac16 venv % source bin/activate # activate the venv
(venv) (base) lisa@mac16 venv % python --version ## show the python version of this venv
Python 3.11.3
(venv) (base) lisa@mac16 venv % which pip # see the pip associated with this python version 
/Users/lisa/Desktop/dbt/01-dbt-core/code/venv/bin/pip

(venv) (base) lisa@mac16 venv % pip install dbt-snowflake==1.5.0 # install dbt
(venv) (base) lisa@mac16 venv % dbt # will show its usage info
```

### Setup a dbt 1.5 project, and connect to Snowflake
To run dbt, it requires a dbt config folder to be created in your home dir: 
```console
(base) lisa@mac16 ~ % mkdir ~/.dbt # create a .dbt folder in home dir
```

Next, create a dbt project named "dbtlearn", in your projects folder:
```console
(venv) (base) lisa@mac16 code % dbt init dbtlearn
19:21:16  Running with dbt=1.5.1
Which database would you like to use?
[1] snowflake

(Don't see the one you want? https://docs.getdbt.com/docs/available-adapters)

Enter a number: 1
account (https://<this_value>.snowflakecomputing.com): wbb6....
user (dev username): dbt
[1] password
[2] keypair
[3] sso
Desired authentication type option (enter a number): 1
password (dev password): 
role (dev role): transform
warehouse (warehouse name): COMPUTE_WH
database (default database that dbt will build objects in): AIRBNB
schema (default schema that dbt will build objects in): DEV
threads (1 or more) [1]: 
19:24:58  Profile dbtlearn written to /Users/lisa/.dbt/profiles.yml using target's profile_template.yml and your supplied values. Run 'dbt debug' to validate the connection.
19:24:58  
Your new dbt project "dbtlearn" was created!

For more information on how to configure the profiles.yml file,
please consult the dbt documentation here:

  https://docs.getdbt.com/docs/configure-your-profile

One more thing:

Need help? Don't hesitate to reach out to us via GitHub issues or on Slack:

  https://community.getdbt.com/

Happy modeling!

```

Note that it automatically saves the login info here: `/Users/lisa/.dbt/profiles.yml`. Also, we specified that our target schema name is DEV, which is where dbt will build all the models in. 

To check whether everything is in place, navigate to the newly created "dbtlearn" folder, and run:
```console
(venv) (base) lisa@mac16 code % cd dbtlearn 
(venv) (base) lisa@mac16 dbtlearn % dbt debug # connect to db, check configs
20:02:10  Running with dbt=1.5.1
20:02:10  dbt version: 1.5.1
20:02:10  python version: 3.11.3
20:02:10  python path: /Users/lisa/Desktop/dbt/01-dbt-core/code/venv/bin/python3.11
20:02:10  os info: macOS-13.0-arm64-arm-64bit
20:02:10  Using profiles.yml file at /Users/lisa/.dbt/profiles.yml
20:02:10  Using dbt_project.yml file at /Users/lisa/Desktop/dbt/01-dbt-core/code/dbtlearn/dbt_project.yml
20:02:10  Configuration:
20:02:10    profiles.yml file [OK found and valid]
20:02:10    dbt_project.yml file [OK found and valid]
20:02:10  Required dependencies:
20:02:10   - git [OK found]

20:02:10  Connection:
20:02:10    account: wbb6....
20:02:10    user: dbt
20:02:10    database: AIRBNB
20:02:10    schema: DEV
20:02:10    warehouse: COMPUTE_WH
20:02:10    role: transform
20:02:10    client_session_keep_alive: False
20:02:10    query_tag: None
20:02:11    Connection test: [OK connection ok]

20:02:11  All checks passed!

```

### dbt project structure
Take a look at the "dbt_project.yml" file:
- versions
- folder paths
- clean targets
- models, project name

Recommend to remove the example tree under project name at the bottom of this file. Also, delete the "example" folder in the models folder. 

### dbt power user extension for VS Code
Recommend to install the dbt Power User extension. Remember to add below to settings.json in workspace settings. 
```json
"files.associations": {
  "*.sql": "jinja-sql"
},
```

### data flow overview
airbnb.hosts, airbnb.listings, airbnb.reviews are 3 raw tables. Data lineage chart will be shown later. 

## Models
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
 select
   *
 from
   airbnb.raw.raw_listings
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

src_reviews.sql:
```sql
with raw_reviews as (
  select
    *
  from
    airbnb.raw.raw_reviews
)
select
  listing_id,
  date as review_date,
  reviewer_name,
  comments as review_text,
  sentiment as review_sentiment
from
  raw_reviews
```

src_hosts.sql:
```sql
with raw_hosts as (
  select
    *
  from
    airbnb.raw.raw_hosts
)
select
  id as host_id,
  name as host_name,
  is_superhost,
  created_at,
  updated_at
from
  raw_hosts
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

## Materializations
4 types of materializations:
- View. Is default. Lightweight. Not good for reuse. 
- Table. Good for reuse. 
- Incremental (table appends). Appends to tables, good for fact tables. Do not update historical records. 
- Ephemeral (CTEs). Not materialized in any way, just an alias. 

In the "models" folder, create a new folder "dim". Inside it, create a new file "dim_listings_cleansed.sql":
```sql
with src_listings as (
  select
    *
  from
    {{ ref('src_listings') }}
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
from
  src_listings
```

Note the reference used in it. dbt heavily relies on Jinja. 

And another model "models/dim/dim_hosts_cleansed.sql":
```sql
with src_hosts as (
  select
    *
  from
    {{ ref('src_hosts') }}
)
select
  host_id,
  nvl(host_name, 'anonymous') as host_name, -- replace nulls with anonymous
  is_superhost,
  created_at,
  updated_at
from
  src_hosts
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

Inside teh "models" folder, create a "fct" folder to store the fact models. 

Add model "fct_reviews.sql":
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

Note that this model is incremental, and the run will fail if the upstream schema changes. The incremental condition is specified at the end of the file. 

Now run `dbt run`, and obtain the 3 views and 3 tables in snowflake. 

To simulate new recording being added to raw data, manually execute below in snowflake:
```sql
insert into 
  airbnb.raw.raw_reviews
values (
  3176, 
  current_timestamp(), 
  'Zoltan', 
  'excellent stay!', 
  'positive')
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

Inside the dim folder, create "dim_listings_w_hosts.sql":
```sql
with
l as (
  select
    *
  from
    {{ ref('dim_listings_cleansed') }}
),

h as (
  select 
    *
  from 
    {{ ref('dim_hosts_cleansed') }}
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
from 
  l
  left join 
  h 
  on (h.host_id = l.host_id)
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

Do this to both "dim_listings_cleansed.sql" and "dim_hosts_cleansed". Run all the models, and see two views and two tables in snowflake. 

## Seeds and sources
Seeds: local files that dbt uploads to the data warehouse.

Sources: an abstraction layer on top of your input tables. 

Source freshness can be checked automatically. 

Seeds live in the "seeds" folder in a dbt project. 

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

Create a "mart" folder inside the "models" folder. This folder will be accessed by BI tools. Create a "full_moon_reviews.sql" inside "mart" folder:
```sql
{{ 
  config(materialized = 'table') 
}}

with fct_reviews as (
  select 
    * 
  from 
    {{ ref('fct_reviews') }}
),

full_moon_dates as (
  select 
    * 
  from 
    {{ ref('seed_full_moon_dates') }} -- refer to seeds directly, like a model
)

select
  r.*,
  case
    when fm.full_moon_date is null then 'not full moon'
    else 'full moon'
  end as is_full_moon
from
  fct_reviews r
  left join 
  full_moon_dates fm
  on 
    to_date(r.review_date) = dateadd(day, 1, fm.full_moon_date)
```

Sources can be defined in yaml files in the "models" folder. Create a "sources.yml":
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

With this, you can then name your raw tables as "source tables", and use their new names in model definitions (such as `{{ source('airbnb', 'listings')}}` to refer to the `raw_listings` table). In this way, if later these source tables move to other places, you can just update this file in one place, and all references of them from the models will all be updated.

Rewrite the 3 models in "src" folder, "src_hosts.sql":
```sql
with raw_hosts as (
  select
    *
  from
    {{ source('airbnb', 'hosts')}} -- airbnb.raw.raw_hosts
)
select
  id as host_id,
  name as host_name,
  is_superhost,
  created_at,
  updated_at
from
  raw_hosts
```

"src_listings.sql":
```sql
with raw_listings as (
 select
   *
 from
   {{ source('airbnb', 'listings')}} -- airbnb.raw.raw_listings
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

"src_reviews.sql":
```sql
with raw_reviews as (
  select
    *
  from
    {{ source('airbnb', 'reviews')}} -- airbnb.raw.raw_reviews
)
select
  listing_id,
  date as review_date,
  reviewer_name,
  comments as review_text,
  sentiment as review_sentiment
from
  raw_reviews
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

In "sources.yml", you can define source freshness constraints, such as for the reviews source table: 
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

## snapshots
SCD type 2 in dbt: "dbt_valid_from" and "dbt_valid_to" cols indicate how historical records are active during which time span. If "dbt_valid_to" is null, that means the record is most current. 

You can use either of the strategies: 
- A unique key, and an updated_at field
- Any change in a set of cols, or all cols, will be picked up as an update

Snapshots live in the "snapshots" folder, which can be verified in the "dbt_project.yml" file. 

Here we create two snapshots, one for raw_listings and one for raw_hosts. 

In "snapshots" folder, create a new file "scd_raw_listings.sql":
```sql
{% snapshot scd_raw_listings %} -- snapshot table name
{{
  config(
    target_schema='dev',
    unique_key='id',
    strategy='timestamp', -- which strategy to use
    updated_at='updated_at',
    invalidate_hard_deletes=True -- make sure to pick up deletes, and seal it with the correct timestamp of deletion
  )
}}

select 
  * 
from 
  {{ source('airbnb', 'listings') }}

{% endsnapshot %}
```

Run `dbt snapshot` to create the initial snapshot, and see the "scd_raw_listings" table in "dev" schema. 
```console
(venv) (base) lisa@mac16 dbtlearn % dbt snapshot
19:41:46  Running with dbt=1.5.1
19:41:47  Found 8 models, 0 tests, 1 snapshot, 0 analyses, 321 macros, 0 operations, 1 seed file, 3 sources, 0 exposures, 0 metrics, 0 groups
19:41:47  
19:41:50  Concurrency: 1 threads (target='dev')
19:41:50  
19:41:50  1 of 1 START snapshot dev.scd_raw_listings ..................................... [RUN]
19:41:53  1 of 1 OK snapshotted dev.scd_raw_listings ..................................... [success in 2.49s]
19:41:53  
19:41:53  Finished running 1 snapshot in 0 hours 0 minutes and 6.00 seconds (6.00s).
19:41:53  
19:41:53  Completed successfully
19:41:53  
19:41:53  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

Note the new cols in this "scd_raw_listings" table - "dbt_valid_from" col have same val as "dbt_updated_at", and "dbt_valid_to" col all have NULLs. 

If we make an update to the raw table from Snowflake:
```sql
update 
  airbnb.raw.raw_listings 
set 
  minimum_nights = 30,
  updated_at = current_timestamp() 
where 
  id = 3176
;
```

And run `dbt snapshot` to update the snapshot, then in Snowflake run`select * from airbnb.dev.scd_raw_listings where id=3176;`, we can then see these 2 records:
```
ID    ...  UPDATED_AT               DBT_SCD_ID                        DBT_UPDATED_AT           DBT_VALID_FROM           DBT_VALID_TO
3176  ...  2023-06-07 12:47:13.948  fa6d509ef4e446916277df0a755c73ac  2023-06-07 12:47:13.948  2023-06-07 12:47:13.948  NULL
3176  ...  2009-06-05 21:34:42.000  c9e3bc0b5eb3a808ee31530eccdfa503  2009-06-05 21:34:42.000	 2009-06-05 21:34:42.000  2023-06-07 12:47:13.948
```

Behind the scene, this is a merge statement against the snapshot table, run by dbt. 

Similarly, create "scd_raw_hosts" in the "snapshots" folder:
```sql
{% snapshot scd_raw_hosts %}

{{
  config(
    target_schema='dev',
    unique_key='id',
    strategy='timestamp',
    updated_at='updated_at',
    invalidate_hard_deletes=true
  )
}}

select 
  * 
from 
  {{ source('airbnb', 'hosts') }}

{% endsnapshot %}
```
And run `dbt snapshot`. 

## tests


## Macros, custom tests and packages


## documentation


## Analyses, hooks & exposures


## Debugging tests


























