# 1. dbt Cloud and Snowflake quickstart

## Prerequisites
- Snowflake trial account
- dbt Cloud account

## Load data in to snowflake
Create objects in snowflake for dbt:
```sql
create warehouse transforming;

create database raw;

create database raw;
create schema raw.jaffle_shop;
create schema raw.stripe;

create database analytics;

create table raw.jaffle_shop.customers
( id integer,
  first_name varchar,
  last_name varchar
);
copy into raw.jaffle_shop.customers (id, first_name, last_name)
from 's3://dbt-tutorial-public/jaffle_shop_customers.csv'
file_format = (
    type = 'CSV'
    field_delimiter = ','
    skip_header = 1
    ); 

create table raw.jaffle_shop.orders
( id integer,
  user_id integer,
  order_date date,
  status varchar,
  _etl_loaded_at timestamp default current_timestamp
);
copy into raw.jaffle_shop.orders (id, user_id, order_date, status)
from 's3://dbt-tutorial-public/jaffle_shop_orders.csv'
file_format = (
    type = 'CSV'
    field_delimiter = ','
    skip_header = 1
    );

create table raw.stripe.payment 
( id integer,
  orderid integer,
  paymentmethod varchar,
  status varchar,
  amount integer,
  created date,
  _batched_at timestamp default current_timestamp
);
copy into raw.stripe.payment (id, orderid, paymentmethod, status, amount, created)
from 's3://dbt-tutorial-public/stripe_payments.csv'
file_format = (
    type = 'CSV'
    field_delimiter = ','
    skip_header = 1
    );

```

## Connect dbt Cloud to sf account
Connection: Snowflake; Name: Snowflake, Account: crXXXXX6 (the sf account id), Database: analytics, Warehouse: transforming, Role: leave empty, Auth Method: Username & Password, Username: your username, Password: your pwd, Schema: dbt_lisa, Target Name: default, Threads: 4. Test connection and click Next. Setup a Repository: Managed, Name: dbt-cloud-test-repo. Click Create. 

## Initialize the dbt project
- Click "Start developing in the IDE".
- Click "Initialize your project". This builds out your folder structure with example models.
- Click "Commit and sync". This creates the first commit to your repo and allows you to open a branch where you can add new dbt code.
- Create branch -> branch test (because the main branch is read-only)
- Query data from your warehouse and execute dbt run. Create new file, add `select * from raw.jaffle_shop.customers` to the it, save. In the command line bar, enter `dbt run` and click Enter. You should see a dbt run succeeded message. You can also click Preview to see query results. 

## Build a model
- Create a branch if necessary
- Click the ... next to the "models" in File Explorer, select Create file. Name the file "customers.sql", then click Create.
- Copy the below query into the file and Save.
- Enter `dbt run` in the command prompt and get a successful run, and see the 3 models, including the customers view, and two demo example models (a view and a table).
- This customers view can then then be used in a BI tool

```sql
with customers as (
    select
        id as customer_id,
        first_name,
        last_name
    from raw.jaffle_shop.customers
),

orders as (
    select
        id as order_id,
        user_id as customer_id,
        order_date,
        status
    from raw.jaffle_shop.orders
),

customer_orders as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(order_id) as number_of_orders
    from orders
    group by 1
),

final as (
    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_order_date,
        customer_orders.most_recent_order_date,
        coalesce(customer_orders.number_of_orders, 0) as number_of_orders
    from customers
    left join customer_orders using (customer_id)
)

select * from final
```

## Change how the model is materialized
By default, everything gets created as a view. dbt allows you to change the way a model is materialized (table/view/incremental/ephemeral/custom(advanced)) in your warehouse, by editing the `dbt_project.yml` file.

For example, by changing these lines: 
```yml
models:
  my_new_project:
    # Applies to all files under models/example/
    example:
      materialized: view
```
to
```yml
models:
  my_new_project:
    materialized: table
    # Applies to all files under models/example/
    example:
      materialized: view
```
and save the file, and `dbt run`, now in snowflake, the customers view is now a table instead. But the models in the example folder didn't change types. To achieve this manually with out dbt, we would need a drop view and a create table command. 

Instead of setting all models as view by default, you can only specify for the customers model "customers.sql" by adding below snipped to top of this model's file:
```sql
{{
  config(
    materialized='view'
  )
}}
```
`dbt run` and see this customers object is back to a view in snowflake. 

## Delete models
To delete models in the example folder, follow two steps
1. delete the models/example folder
2. delete the `example:` key and values from the "dbt_project.yml" file

Note: 
- If you delete a model from your dbt project, dbt does not automatically drop the relation from your warehouse. This can also happen if you switch a model from view/table, to ephemeral
- When you remove models from your dbt project, you should manually drop the related relations from your warehouse.

## Build models on top of other models
As a best practice in SQL, you should separate logic that cleans up your data from logic that transforms your data (by using CTEs, etc). We can separate CTEs from current "models/customers.sql" file, and refer to them like this:

Create file "models/stg_customers.sql" as
```sql
select
    id as customer_id,
    first_name,
    last_name
from raw.jaffle_shop.customers
```

Create file "models/stg_orders.sql" as
```sql
select
    id as order_id,
    user_id as customer_id,
    order_date,
    status
from raw.jaffle_shop.orders
```

Edit file "models/customers.sql" to
```sql
with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_orders as (
    select
        customer_id,

        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(order_id) as number_of_orders
    from orders
    group by 1
),

final as (
    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_order_date,
        customer_orders.most_recent_order_date,
        coalesce(customer_orders.number_of_orders, 0) as number_of_orders
    from customers
    left join customer_orders using (customer_id)
)

select * from final
```

Execute `dbt run`. Can see separate views/tables were created for stg_customers, stg_orders and customers. dbt inferred the order to run these models. Because customers depends on stg_customers and stg_orders, dbt builds customers last. You do not need to explicitly define these dependencies.

Notes:
- To run one model at a time, use `dbt run --select model_to_run`, such as `dbt run --select customers`. 
- Model names has to be unique, even across folders. Use custom aliases to create objects with same names in different schemas, etc

## Add tests to models
Tests can validate that your models are working correctly.

To add tests to your project:
1. Create a new YAML file "models/schema.yml" (can be any name you want)
2. Add below contents to the file
3. Run `dbt test`, and confirm that all your tests passed.

```yml
version: 2

models:
  - name: customers
    columns:
      - name: customer_id
        tests:
          - unique
          - not_null

  - name: stg_customers
    columns:
      - name: customer_id
        tests:
          - unique
          - not_null

  - name: stg_orders
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
      - name: status
        tests:
          - accepted_values:
              values: ['placed', 'shipped', 'completed', 'return_pending', 'returned']
      - name: customer_id
        tests:
          - not_null
          - relationships:
              to: ref('stg_customers')
              field: customer_id
```

Out of the box, dbt ships with the following tests:
- unique
- not_null
- accepted_values
- relationships (i.e. referential integrity)
You can also write your own custom schema tests.

To test one model at a time, use `dbt test --select customers`. 

Recommend every model to have a test on a primary key (a column that is `unique` and `not_null`).

You should run tests whenever you are writing new code (to ensure you haven't broken any existing models by changing SQL), and whenever you run your transformations in production (to ensure that your assumptions about your source data are still valid).

## Document the models
Update "models/schema.yml" file with descriptions: 
```yaml
version: 2

models:
  - name: customers
    description: One record per customer
    columns:
      - name: customer_id
        description: Primary key
        tests:
          - unique
          - not_null
      - name: first_order_date
        description: NULL when a customer has not yet placed an order.

  - name: stg_customers
    description: This model cleans up customer data
    columns:
      - name: customer_id
        description: Primary key
        tests:
          - unique
          - not_null

  - name: stg_orders
    description: This model cleans up order data
    columns:
      - name: order_id
        description: Primary key
        tests:
          - unique
          - not_null
      - name: status
        tests:
          - accepted_values:
              values: ['placed', 'shipped', 'completed', 'return_pending', 'returned']
```

Run `dbt docs generate` to generate the documentation for your project. dbt introspects your project and your warehouse to generate a JSON file with rich documentation about your project. Click the book icon in the Develop interface to launch documentation in a new tab.

## Commit changes
"Commit and sync" -> "Merge this branch to main"

## Create a deployment env, create & run a job
Deploy -> Environments -> Create Environment -> Name: env_prod, Username: your-username, Password: your_pwd, Schema: analytics -> Save 

Jobs are a set of dbt commands that you want to run on a schedule, such as `dbt run` and `dbt test`.

As this project business gets more customers, because you built the customers model as a table, you'll need to periodically rebuild this table to make it stays up-to-date. A job can achieve this. 

Create one -> Job Name: prod_run, check "Generate docs on run", commands: `dbt run`, `dbt test`; Do not need to run this simple example on schedule. -> Save -> Run now

Recommend setting up email/Slack notifications (Account Settings > Notifications) for any failed runs. Then, debug these runs the same way you would debug any runs in development.










