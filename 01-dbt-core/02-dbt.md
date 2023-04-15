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

## env setup
Create db, role, user, warehouse, and grant privileges for objects in snowflake for dbt: 
```sql
use role accountadmin;

create database if not exists airbnb;
create schema if not exists airbnb.raw;

create warehouse if not exists compute_wh;

create role if not exists transform;
create user if not exists dbt
  password='XXX' -- supply your pwd here
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
create or replace table raw_listings
                    (id integer,
                     listing_url string,
                     name string,
                     room_type string,
                     minimum_nights integer,
                     host_id integer,
                     price string,
                     created_at datetime,
                     updated_at datetime);
copy into raw_listings (id,
                        listing_url,
                        name,
                        room_type,
                        minimum_nights,
                        host_id,
                        price,
                        created_at,
                        updated_at)
                   from 's3://dbtlearn/listings.csv'
                    file_format = (type = 'csv' skip_header = 1
                    field_optionally_enclosed_by = '"');

create or replace table raw_reviews
                    (listing_id integer,
                     date datetime,
                     reviewer_name string,
                     comments string,
                     sentiment string);
copy into raw_reviews (listing_id, date, reviewer_name, comments, sentiment)
                   from 's3://dbtlearn/reviews.csv'
                    file_format = (type = 'csv' skip_header = 1
                    field_optionally_enclosed_by = '"');

create or replace table raw_hosts
                    (id integer,
                     name string,
                     is_superhost string,
                     created_at datetime,
                     updated_at datetime);
copy into raw_hosts (id, name, is_superhost, created_at, updated_at)
                   from 's3://dbtlearn/hosts.csv'
                    file_format = (type = 'csv' skip_header = 1
                    field_optionally_enclosed_by = '"');
```

## Models


## Materializations


## Seeds and sources


## snapshots


## tests


## Macros, custom tests and packages


## documentation


## Analyses, hooks & exposures


## Debugging tests


























