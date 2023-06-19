# 4. Jinja, macros, packages
## Jinja
Jinja: Python based templating language. 
- Enables better collaboration
- Write sql faster - less lines of code
- Sets foundation for macros

```sql
{% for i in range(4) %}
  select {{ i }} as number {% if not loop.last %} union all {% endif %}
{% endfor %}
```

Click the "Compile" button, and get the compiled sql query (that can then be run directly against a data warehouse etc. ): 
```sql
select 0 as number union all
select 1 as number union all
select 2 as number union all
select 3 as number
```

Click "Preview" button to see the results - a column named "number", with vals from 0 to 3. 

### Jinja basics
Supports basic Python data objects, such as list/dict/...
```sql
-- set a variable (statements)
{% set my_str = 'Hello world! ' %} 
{% set my_num = 10 %}

-- print this variable (expressions)
{{ my_str }} 
{{ my_num }} 
Print both the string and the number together: {{ my_str }} {{ my_num }} 

-- comment
{#
This is a Jinja comment 
#}

-- use lists
{% set my_list = ['a', 'b', 'c'] %}
-- print the first val in the list
{{ my_list[0] }} 

-- iteration
{% for item in my_list %}
  Cur val is {{ item }}
{% endfor %}

-- print diff things based on a var
{% set temperature = 45 %}

{% if temperature < 65 %}
  Temperature is low. 
{% else %}
  Temperature is high. 
{% endif %}

-- similar to above
{% set my_list = ['a', 'b', 'c'] %}

{% for item in my_list %} -- this line doesn't explicitly print, but takes an empty line in the output. using {%- the logic block -%} eliminates the lines before and after it. 
  {% if item == 'a' %}
    {% set my_var = 1 %}
  {% else %}
    {% set my_var = 0 %} 
  {% endif %}
{% endfor %}

-- use dicts
{% set my_dict = {
  'key1': 'val1',
  'key2': 'val2'
} %}

{{ my_dict['key2'] }}

```

### Use Jinja in dbt models
Before using Jinja, the sql file "models/marts/core/int_orders__pivoted.sql":
```sql
with payments as (
  select * from {{ ref('stg_payments') }}
)

pivoted as (
  select
    order_id,
    sum(case when payment_method = 'bank_transfer' then amount else 0 end) as bank_transfer_amount,
    sum(case when payment_method = 'coupon' then amount else 0 end) as coupon_amount,
    sum(case when payment_method = 'credit_card' then amount else 0 end) as credit_card_amount,
    sum(case when payment_method = 'gift_card' then amount else 0 end) as gift_card_amount
  from payments
  where status = 'success'
  group by 1
)

select * from pivoted
```

Using Jinja, it becomes:
```sql
{%- set payment_methods = ['bank_transfer', 'coupon', 'credit_card', 'gift_card'] -%}

with payments as (
  select * from {{ ref('stg_payments') }}
)

pivoted as (
  select
    order_id,
    {% for payment_method in payment_methods -%}
      sum(case when payment_method = '{{ payment_method }}' then amount else 0 end) as {{ payment_method }}_amount
      {%- if not loop.last -%}
        ,
      {%- endif %}
    {%- endfor -%}

  from payments
  where status = 'success'
  group by 1
)

select * from pivoted
```

Click compile sql to examine the generated sql statement. 

This code is also easy to maintain - if in the future, a new payment_method is added, you modify the code in only one place. 

### References
- https://jinja.palletsprojects.com/page/templates/
- http://jinja.quantprogramming.com/


## Macros
Some logic in sql are used often, such as pivot, date/times, de-dup, etc. Macros allow you to re-use this logic. 

Packages let you import macros (written by other people) into your project. 

Create a file for a macro "macros/cents_to_dollars.sql":
```sql
{% macro cents_to_dollars(column_name, decimal_places=2) -%} -- 2nd arg has default val
round( 1.0 * {{ column_name }} / 100, {{ decimal_places }} ) -- refer to python var using {{ ... }}
{%- endmacro %}
```

Refer to it in sql using (note that args has to be python literals):
```sql
select
  ...
  {{ cents_to_dollars('amount_cents', 4) }} as amount_dollars,
  ...
from ...
```

When you write macros, click the "compile" button to see the compiled sql that can be run. 

Another example: 
Create a file for a macro "macros/limit_data_in_dev.sql":
```sql
{% macro limit_data_in_dev(column_name, num_of_days=3) %}
{% if target.name == 'dev' %} -- only apply to dev
where {{ column_name }} >= dateadd('day', -{{ num_of_days }}, current_timestamp)
{% endif %}
{% endmacro %}
```

Refer to it in sql using:
```sql
select ... from ...

{{ limit_data_in_dev('created_at', 10) }}
```
or
```sql
select ... from ...

{{ limit_data_in_dev(column_name='created_at', num_of_days=10) }}
```

Tradeoff of using micros: lose some readability. 


## Packages
You can import models/macros (written by others) into your project. 

For example, other people already modeled common data sources on a high level, such as for facebook ads, snowplow, stripe data, etc, so you can import a package for those sources and instantly model these in your project. 

Popular macro packages, such as dbt utils, can be found at dbt hub. For example, a macro that let you create a col of dates in your preferred range/interval. 

An example of "packages.yml" file:
```yml
packages:
  - package: fivetran/github
    version: 0.1.1
  - git: https://github.com/fishtown-analytics/dbt-tuils.git
    revision: master
  - local: sub-project
```

If you refer to a git repo, it needs to be visible from your current github account. Useful if you have a private repo. 

If you refer to a local dir, it needs to be a relative path to the yml file. Good for version control your packages when you develop them. 

Run `dbt deps` to install these packages specified in that yml file. 

### Example: using macros in packages
```sql
-- a week per day, starting from 01/01/2023, to a week later from today
{{ 
  dbt_utils.date_spine(
    datepart="day",
    start_date="to_date('01/01/2023', 'mm/dd/yyyy')"
    end_date="dateadd(week, 1, current_date)"
  )
}}
```

To look at how this macros is written, go to their github page. Behind the scene, macros may call macros, etc. 

Another example, creating surrogate key:
```
select 
  {{ dbt_utils.surrogate_key(['customer_id', 'order_date']) }} as id,
  customer_id,
  order_date,
  count(*)
from {{ ref('stg_orders') }}
group by 1,2,3
```

dbt-utils are written in such a way that it works across different brand of databases. 

### Example: using models in packages
Example yml file "packages.yml":
```yml
packages:
  - package: gitlabhq/snowflake_spend
    version: 1.2.0
```

Create a seed file "seeds/snowflake_contract_rates.csv":
```csv
effective_date,rate
2018-06-01,2.55
2019-08-01,2.48
```
and run `dbt seed`, then `dbt run`, and you get all the amortized models. These models do not live in the "models" folder - they live in their own subfolder in the project folder. 

To run/test a model from a certain package: `dbt test -m package:snowflake_spend`

## Advanced Jinja and Macros
### Example 1: Grant privilege
Create a new file "macros/grant_select.sql":
```sql
{% macro grant_select(schema=target.schema, role=target.role) %}

  {% set my_query %}
    grant usage on schema {{ schema }} to role {{ role }};
    grant select on all tables in schema {{ schema }} to role {{ role }};
    grant select on all views in schema {{ schema }} to role {{ role }};
  {% endset %}

  {{ log('Granting select on all tables and views in schema ' ~ schema ~ ' to role ' ~ role, info=True) }} -- info=True makes output goes into both logs and terminal
  {% do run_query(sql) %}
  {{ log('Privileges granted. ', info=True) }}

{% endmacro %}
```

Run `dbt run-operation grant_select` to run this query. 

### Example 2: Use query results to build sql code dynamically
Create a new macro file "macros/template_example.sql": 
```sql
{% macro template_example() %}
  
  {% set my_query %}
    select true as bool
  {% endset %}

  {% if execute %} 
    {% set my_results = run_query(my_query).columns[0].values()[0] %}
    -- columns[0] means select the firs col, values() means get vals of this col
    {{ log('SQL results ' ~ my_results, info=True) }}

    select 
      {{ my_results}} as my_new_col,
      ...
    from my_table
  {% endif %}
{% endmacro %}
```

Create a new model file "models/template_example_model.sql": 
```sql
{{ template_example() }}
```

`execute == True` in the macro tells dbt to run the query before it compiles. So when we compile the model file, it incorporates the results of the 1st query into the 2nd query.

Another example for this. Create a new macro file "macros/union_tables_by_prefix.sql":
```sql
{%- macro union_tables_by_prefix(database, schema, prefix) -%}

  {%- set tables = dbt_utils.get_relations_by_prefix(database=database, schema=schema, prefix=prefix) -%}

  {% for table in tables %} -- loop over each item in the list

      {%- if not loop.first -%}
      union all 
      {%- endif %}
        
      select * from {{ table.database }}.{{ table.schema }}.{{ table.name }}
      
  {% endfor -%}
  
{%- endmacro -%}
```

And the model file "models/union_tables_by_orders_prefix.sql" that uses it:
```sql
{{ 
  union_tables_by_prefix(
      database='raw',
      schema='dbt_learn_jinja', 
      prefix='orders__'
  )
}}
```

Click "compile" in the model page to see the compiled query with unions. 

My note: should read through all macro docs in dbt-utils package. 

### Example 3: Clean stale models







