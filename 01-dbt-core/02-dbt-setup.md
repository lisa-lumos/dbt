# 2. dbt overview and env setup
## dbt Overview
dbt transforms data in the DWH with SQL select statements. It will deploy your analytics code following software engineering best practices, like modularity, portability, CICD, testing and documentation. You will write your code, and compile it to sql and execute it, the transformations are version controlled. It allow you to create different environments like dev/prod, and easily switch between them. In terms of performance, dbt will take your models, understand the dependencies between them, and will create a dependency order, and parallelize the way your models are built. 

## Use case and Input data model Overview
Suppose you are a analytics engineer in Airbnb that is responsible for all the data flow in Berlin, Germany and Europe. You need to import your data into a data warehouse, cleanse and expose the data to a BI tool. You will also need to write test, automation and documentation. Our data source is Airbnb's data sharing site `insideairbnb.com/berlin/`. 

The requirements: 
- Modeling changes are easy to follow and revert
- Explicit dependencies between models, so the framework knows in which order to execute different steps in the pipeline; also these dependencies need to be easy to explore and overview
- Data quality tests
- Error reporting
- Track history of dimension tables, for new records, and slowly changing dimensions
- Easy-to-access documentation

## Snowflake setup
Create db, role, service user, warehouse, and grant privileges for objects in snowflake for dbt: 
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

## dbt setup
Install Python 3.11 from official website. 

Then setup virtual env, and install dbt:
```console
(base) lisa@mac16 ~ % /usr/local/bin/python3 -m venv /Users/lisa/Desktop/dbt/01-dbt-core/code/venv    # create a venv in the "venv" folder
(base) lisa@mac16 % cd /Users/lisa/Desktop/dbt/01-dbt-core/code/venv

(base) lisa@mac16 venv % source bin/activate        # activate the venv

(venv) (base) lisa@mac16 venv % python --version    # show the python version of this venv
Python 3.11.3

(venv) (base) lisa@mac16 venv % which pip           # see the pip associated with this python version 
/Users/lisa/Desktop/dbt/01-dbt-core/code/venv/bin/pip

(venv) (base) lisa@mac16 venv % pip install dbt-snowflake==1.5.0    # install dbt

(venv) (base) lisa@mac16 venv % dbt                 # will show its usage info
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
(venv) (base) lisa@mac16 dbtlearn % dbt debug     # connect to db, check configs
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

## dbt project structure
Take a look at the "dbt_project.yml" file:
- versions
- folder paths
- clean targets
- models, project name

Recommend to remove the example tree under project name at the bottom of this file. Also, delete the "example" folder in the models folder. 

## dbt power user extension for VS Code
Recommend to install the dbt Power User extension. Remember to add below to settings.json in workspace settings. 
```json
"files.associations": {
  "*.sql": "jinja-sql"
},
```

## data flow overview
airbnb.hosts, airbnb.listings, airbnb.reviews are 3 raw tables. Data lineage chart will be shown later. 
