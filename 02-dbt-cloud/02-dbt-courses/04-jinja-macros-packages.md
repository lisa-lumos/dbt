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





## Packages








## Advanced Jinja and Macros










