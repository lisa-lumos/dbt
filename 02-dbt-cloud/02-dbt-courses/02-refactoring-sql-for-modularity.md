# Refactoring SQl for Modularity
## Migrating legacy code
Assume you have a legacy query "customer_orders.sql":
```sql
select 
    orders.id as order_id,
    orders.user_id as customer_id,
    last_name as surname,
    first_name as givenname,
    first_order_date,
    order_count,
    total_lifetime_value,
    round(amount/100.0,2) as order_value_dollars,
    orders.status as order_status,
    payments.status as payment_status
from raw.jaffle_shop.orders as orders

join (
      select 
        first_name || ' ' || last_name as name, 
        * 
      from raw.jaffle_shop.customers
) customers
on orders.user_id = customers.id

join (

    select 
        b.id as customer_id,
        b.name as full_name,
        b.last_name as surname,
        b.first_name as givenname,
        min(order_date) as first_order_date,
        min(case when a.status NOT IN ('returned','return_pending') then order_date end) as first_non_returned_order_date,
        max(case when a.status NOT IN ('returned','return_pending') then order_date end) as most_recent_non_returned_order_date,
        COALESCE(max(user_order_seq),0) as order_count,
        COALESCE(count(case when a.status != 'returned' then 1 end),0) as non_returned_order_count,
        sum(case when a.status NOT IN ('returned','return_pending') then ROUND(c.amount/100.0,2) else 0 end) as total_lifetime_value,
        sum(case when a.status NOT IN ('returned','return_pending') then ROUND(c.amount/100.0,2) else 0 end)/NULLIF(count(case when a.status NOT IN ('returned','return_pending') then 1 end),0) as avg_non_returned_order_value,
        array_agg(distinct a.id) as order_ids

    from (
      select 
        row_number() over (partition by user_id order by order_date, id) as user_order_seq,
        *
      from raw.jaffle_shop.orders
    ) a

    join ( 
      select 
        first_name || ' ' || last_name as name, 
        * 
      from raw.jaffle_shop.customers
    ) b
    on a.user_id = b.id

    left outer join raw.stripe.payment c
    on a.id = c.orderid

    where a.status NOT IN ('pending') and c.status != 'fail'

    group by b.id, b.name, b.last_name, b.first_name

) customer_order_history
on orders.user_id = customer_order_history.customer_id

left outer join raw.stripe.payment payments
on orders.id = payments.orderid

where payments.status != 'fail'
```

In an empty dbt project, in the "models" folder, create a new subfolder "legacy" (which will be eventually deprecated), and inside it, a new file "customer_orders.sql". Paste the legacy code inside. 

If the sql need to be changed into Snowflake flavor, this is where to do it. 

Run `dbt run -m customer_orders`, to see if the query is right. 

## Implementing sources
aka, translating hard-coded table references. In this example, the sources are: `raw.jaffle_shop.orders`, `raw.jaffle_shop.customers`, `raw.stripe.payment`. 

Inside the "models" folder, create new folders/subfolders "marts", "staging", "staging/jaffle_shop", "staging/stripe". You can have both sources defined in one yaml file, but separating them is better organized. 

Create new files "models/staging/jaffle_shop/_sources.yml", "models/staging/stripe/_sources.yml". Note that two yml files can have the same names. 

"models/staging/jaffle_shop/_sources.yml":
```yml
version: 2

sources:
  - name: jaffle_shop
    database: raw
    tables:
      - name: customers
      - name: orders
```


"models/staging/stripe/_sources.yml":
```yml
version: 2

sources:
  - name: stripe
    database: raw
    tables:
      - name: payment
```

Redirect sources in "models/legacy/customer_orders.sql" (Note that typing __source gives snippets of source syntax):
```sql
select 
    orders.id as order_id,
    orders.user_id as customer_id,
    last_name as surname,
    first_name as givenname,
    first_order_date,
    order_count,
    total_lifetime_value,
    round(amount/100.0,2) as order_value_dollars,
    orders.status as order_status,
    payments.status as payment_status
from {{ source('jaffle_shop', 'orders') }} as orders -- new

join (
      select 
        first_name || ' ' || last_name as name, 
        * 
      from {{ source('jaffle_shop', 'customers') }} -- new
) customers
on orders.user_id = customers.id

join (

    select 
        b.id as customer_id,
        b.name as full_name,
        b.last_name as surname,
        b.first_name as givenname,
        min(order_date) as first_order_date,
        min(case when a.status NOT IN ('returned','return_pending') then order_date end) as first_non_returned_order_date,
        max(case when a.status NOT IN ('returned','return_pending') then order_date end) as most_recent_non_returned_order_date,
        COALESCE(max(user_order_seq),0) as order_count,
        COALESCE(count(case when a.status != 'returned' then 1 end),0) as non_returned_order_count,
        sum(case when a.status NOT IN ('returned','return_pending') then ROUND(c.amount/100.0,2) else 0 end) as total_lifetime_value,
        sum(case when a.status NOT IN ('returned','return_pending') then ROUND(c.amount/100.0,2) else 0 end)/NULLIF(count(case when a.status NOT IN ('returned','return_pending') then 1 end),0) as avg_non_returned_order_value,
        array_agg(distinct a.id) as order_ids

    from (
      select 
        row_number() over (partition by user_id order by order_date, id) as user_order_seq,
        *
      from {{ source('jaffle_shop', 'orders') }} -- new
    ) a

    join ( 
      select 
        first_name || ' ' || last_name as name, 
        * 
      from {{ source('jaffle_shop', 'customers') }} -- new
    ) b
    on a.user_id = b.id

    left outer join {{ source('stripe', 'payment') }} c  -- new
    on a.id = c.orderid

    where a.status NOT IN ('pending') and c.status != 'fail'

    group by b.id, b.name, b.last_name, b.first_name

) customer_order_history
on orders.user_id = customer_order_history.customer_id

left outer join {{ source('stripe', 'payment') }} payments  -- new
on orders.id = payments.orderid

where payments.status != 'fail'
```

Run `dbt run -s customer_orders`, to see if the query is right. 

Run `dbt docs generate`, check the sources in the DAG. 

## Choosing a refactoring strategy
This example follows the "refactor along-side" strategy, leaving the legacy code "customer_orders.sql" in place and untouched from this point forward. 

Create a new file "models/marts/fct_customer_orders.sql", and copy everything in "models/legacy/customer_orders.sql" into it. 


## CTE groupings, and cosmetic cleanups
Cosmetic changes: add blank lines, break up long lines using keywords, make all keywords lowercase, to make things more readable. 

Note, in dbt editor, select the text, right click -> Command Palette -> Transform to lowercase. 

CTE groupings. Refactor your code to follow this structure:
```sql
-- with statement
-- import CTEs (from sources)
-- logical CTEs (from subqueries, most nested -> less nested)
-- final CTE (the outer-most select)
-- simple select statement (can be easily modified to "select * from a" to understand model logic)
```

"models/marts/fct_customer_orders.sql":
```sql
with

-- Import CTEs (from sources)
customers as (
    select * from {{ source('jaffle_shop', 'customers') }}
),

orders as (
    select * from {{ source('jaffle_shop', 'orders') }}
),

payments as (
    select * from {{ source('stripe', 'payment') }}
),

-- Logical CTEs (from subqueries, most nested -> less nested)
customers as (
    select 
        first_name || ' ' || last_name as name, 
        * 
    from customers
),

a as (
      select 
        row_number() over (
            partition by user_id 
            order by order_date, id
        ) as user_order_seq,
        *
      from orders
),

b as ( 
    select 
        first_name || ' ' || last_name as name, 
        * 
    from customers
),

customer_order_history as (
    select 
        b.id as customer_id,
        b.name as full_name,
        b.last_name as surname,
        b.first_name as givenname,
        min(order_date) as first_order_date,
        min(case 
            when a.status not in ('returned','return_pending') 
            then order_date 
        end) as first_non_returned_order_date,
        max(case 
            when a.status not in ('returned','return_pending') 
            then order_date 
        end) as most_recent_non_returned_order_date,
        coalesce(max(user_order_seq),0) as order_count,
        coalesce(count(case 
            when a.status != 'returned' 
            then 1 end),
            0
        ) as non_returned_order_count,
        sum(case 
            when a.status not in ('returned','return_pending') 
            then round(c.amount/100.0,2) 
            else 0 
        end) as total_lifetime_value,
        sum(case 
            when a.status not in ('returned','return_pending') 
            then round(c.amount/100.0,2) 
            else 0 
        end)
        / nullif(count(case 
            when a.status not in ('returned','return_pending') 
            then 1 end),
            0
        ) as avg_non_returned_order_value,
        array_agg(distinct a.id) as order_ids
    from a

    join b
    on a.user_id = b.id

    left outer join payments as c
    on a.id = c.orderid

    where a.status not in ('pending') and c.status != 'fail'
    group by b.id, b.name, b.last_name, b.first_name

),

-- Final CTE (the outer-most select)
final as (
    select 
        orders.id as order_id,
        orders.user_id as customer_id,
        last_name as surname,
        first_name as givenname,
        first_order_date,
        order_count,
        total_lifetime_value,
        round(amount/100.0,2) as order_value_dollars,
        orders.status as order_status,
        payments.status as payment_status
    from orders

    join customers
    on orders.user_id = customers.id

    join customer_order_history
    on orders.user_id = customer_order_history.customer_id

    left outer join payments
    on orders.id = payments.orderid

    where payments.status != 'fail'
)

-- Simple Select Statement (can be easily modified to "select * from a" to understand model logic)
select * from final
```
## Centralizing logic in staging models
- Staging models (transform the source only; are building blocks that everyone needs)
- CTEs, or Intermediate models (separating long/reusable logic)
- Final model (joins, etc)

Modify the staging CTEs, collapse the repeating work into them, give them good names, and move the staging CTEs out. Refer to them in "models/marts/fct_customer_orders.sql":
```sql
with

orders as (
  select * from {{ ref('stg_jaffle_shop_orders') }}
),

customers as (
  select * from {{ ref('stg_jaffle_shop_customers') }}
),

payments as (
  select * from {{ ref('stg_stripe_payments') }}
),

customer_order_history as (
  select 
    ...
  from 
    ...
  where 
    ...
  group by 
    ...
),

final as (
  select 
    ...
  from
    ...
)

select * from final
```

Create new file "models/staging/jaffle_shop/stg_jaffle_shop__customers.sql":
```sql
with 

source as (
  select * from {{ source('jaffle_shop', 'customers') }}
), 

transformed as (
  select 
    id as customer_id,
    last_name as surname,
    first_name as givenname,
    first_name || ' ' || last_name as full_name
  from 
    source
)

select * from transformed
```

Create new file "models/staging/jaffle_shop/stg_jaffle_shop__orders.sql":
```sql
with 

source as (
  select * from {{ source('jaffle_shop', 'orders') }}
), 

transformed as (
  select 
    id as order_id,
    user_id as customer_id,
    order_date,
    status as order_status,
    row_number() over (
      partition by user_id
      order by order_date, id
    ) as user_order_seq
  from 
    source
)

select * from transformed
```

Create new file "models/staging/stripe/stg_stripe__payments.sql":
```sql
with 

source as (
  select * from {{ source('stripe', 'payment') }}
), 

transformed as (
  select 
    id as payment_id,
    orderid as order_id,
    status as payment_status,
    round(amount/100.0, 2) as payment_amount
  from 
    source
)

select * from transformed
```

Run the model `dbt run -m +fct_customer_orders` and correct errors, if any. 

## CTEs, or intermediate models?
"models/marts/intermediate/int_orders.sql":
```sql
with

orders as (
    select * from {{ ref('stg_jaffle_shop__orders') }}
),

payments as (
    select * from {{ ref('stg_stripe__payments') }}
    where payment_status != 'fail'
),

order_totals as (
    select
        order_id,
        payment_status,
        sum(payment_amount_usd) as order_value_dollars
    from payments
    group by 1, 2
),

joined as (
    select
        orders.*,
        order_totals.payment_status,
        order_totals.order_value_dollars
    from orders 
    left join order_totals
        on orders.order_id = order_totals.order_id
)

select * from joined
```

"models/staging/jaffle_shop/stg_jaffle_shop__orders.sql":
```sql
with

source as (
    select * from {{ source('jaffle_shop', 'orders') }}
),

transformed as (
    select 
      id as order_id,
      user_id as customer_id,
      status as order_status,
      order_date,
      case 
          when order_status not in ('returned','return_pending') 
          then order_date 
      end as valid_order_date,
      row_number() over (
          partition by user_id 
          order by order_date, id
      ) as user_order_seq
    from source
)

select * from transformed
```

## Final model
"models/marts/fct_customer_orders.sql":
```sql
with 

orders as (
  select * from {{ ref('int_orders') }}
),

customers as (
  select * from {{ ref('stg_jaffle_shop__customers') }}
),

customer_orders as (
  select 
    orders.*,
    customers.full_name,
    customers.surname,
    customers.givenname,

    --- Customer level aggregations
    min(orders.order_date) over(
      partition by orders.customer_id
    ) as customer_first_order_date,

    min(orders.valid_order_date) over(
      partition by orders.customer_id
    ) as customer_first_non_returned_order_date,

    max(orders.valid_order_date) over(
      partition by orders.customer_id
    ) as customer_most_recent_non_returned_order_date,

    count(*) over(
      partition by orders.customer_id
    ) as customer_order_count,

    sum(nvl2(orders.valid_order_date, 1, 0)) over(
      partition by orders.customer_id
    ) as customer_non_returned_order_count,

    sum(nvl2(orders.valid_order_date, orders.order_value_dollars, 0)) over(
      partition by orders.customer_id
    ) as customer_total_lifetime_value,

    array_agg(distinct orders.order_id) over(
      partition by orders.customer_id
    ) as customer_order_ids

  from orders
  inner join customers
    on orders.customer_id = customers.customer_id

),

add_avg_order_values as (
  select
    *,
    customer_total_lifetime_value / customer_non_returned_order_count 
    as customer_avg_non_returned_order_value
  from customer_orders
),

final as (

  select 
    order_id,
    customer_id,
    surname,
    givenname,
    customer_first_order_date as first_order_date,
    customer_order_count as order_count,
    customer_total_lifetime_value as total_lifetime_value,
    order_value_dollars,
    order_status,
    payment_status
  from add_avg_order_values
)

select * from final
```

## Auditing
To make sure the results match. 

First, ensure both models are up to date.

This example used the `audit_helper` package from dbt hub. 

Create a new statement tab:
```yml
{# in dbt Develop #}

  {% set old_etl_relation=ref('customer_orders') -%}

  {% set dbt_relation=ref('fct_customer_orders') %}

  {{ audit_helper.compare_relations(
      a_relation=old_etl_relation,
      b_relation=dbt_relation,
      primary_key="order_id"
  ) }}
```
And preview the results. You can see the "compiled code" tab in the preview area. 

