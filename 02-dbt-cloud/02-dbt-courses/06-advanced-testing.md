# 6. Advanced testing
## Intro
Why test?
- To feel confident in your code, and build trust in the platform
- Ensure your code works as expected, so your consumers get accurate data
- Models documented with assertions can save maintenance time

Testing strategies: Test on a schedule, and fix issues asap. 

Test should be automated, fast, correct, informative, and focused. 

You can use source freshness as the first step of the job, to prevent models from running if data arrival is delayed. 

When you refactor models, the `audit_helper` package can be used to compare your new refactored model, to your existing legacy model. 

### Example - "dbt_meta_testing" package
Include below in the "packages.yml" file. 
```yml
  - package: tnightengale/dbt_meta_testing
    version: 0.3.5
```

Run `dbt deps` to install it. 

Add below to the "dbt_project.yml" file:
```yml
models:
  jaffle_shop:
    # below means all models in the project should have a unique & not null test
    +required_tests: {"unique.*|not_null": 2} # this line is new
```

To run the macro, run `dbt run-operation required_tests`, to test whether all models in the projects have both of the required tests. 

If there is a test that is in the required tests, but you do not need it in a model, you can override it with `{{ config(required_tests=None) }}`. 

You can put `dbt run-operation required_tests` into a CI check, so that each time someone opens oa pull request, this check job kicks off. 

## Test deployment
When to test:
- Test in development to ensure pre-existing assumptions
- Run tests automatically, as an CI check in the PR. `dbt build --models state:modified+`
- If test returns error, you want to prevent running a pipeline
- For deployment jobs, run a schedule
- Test in QA branch before you dbt code reaches main

### Test commands
`dbt test` runs all tests defined on models/sources/snapshots/seeds. 

`dbt test --select my-model` runs all tests for that model, including generic/singular tests. 

`dbt test --select test_type:singular` runs all singular tests. `dbt test --select test_type:generic` runs all generic tests. 

`dbt test --select my-model test_type:singular` runs all singular tests for that model. 

`dbt test --select source:*` runs all tests defined on all sources. 

When you create a deployment job, the commands inside it runs sequentially. If you run a test on your sources, and if the test fails, the subsequent jobs will not run, which saves cost. An example job:
```console
dbt test -s source.*
dbt run
dbt test --exclude source:*
```

`dbt test --select source:jaffle_shop` runs all tests for this source. 

`dbt test --select source:jaffle_shop.orders` runs all test for this source table. 


`dbt build --fail-fast` will test a model as soon as it is created, and will stop the job if a model/test went wrong.

`dbt test --store-failures` stores failures (records) of a test into a table for easier debugging. In the System Logs, you can find the select query `select * from some_table` for a failed test that returned records. You just need to execute the query to see the problematic records that caused the test failure. Note that a test's result will always replace previous run failures (truncate and load all the time), so cannot be used to track failures over time. 

## Custom tests
Custom generic tests: when you want to test the same assumption on many models. 

"tests/generic/assert_column_is_greater_than_five.sql": 
```sql
{% test greater_than_five(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} <= 5

{% endtest %}
```

"models/marts/core/_core.yml":
```yml
...

  - name: orders
    description: ...

    columns:
      - name: amount
        description: ...
        tests: 
          - assert_column_is_greater_than_five # file name of the test

...
```

`dbt run --select orders` will run all tests for this model, including this one. 

Overwriting native tests: You can create engineered tests with the same name with the generic tests to override them. This works for all dbt macros. 

## Tests in packages

### dbt_utils
An example using a test in this package. 

"_core.yml":
```yml
...

  - name: orders
    description: ...
    tests:
      - dbt_utils.expression_is_true:
        expression: "amount" > 5
```

### dbt_expectations
An example using a test in this package. 
"_core.yml":
```yml
...

  - name: orders
    description: ...
    tests:
      - dbt_expectations.expect_column_values_to_be_between:
        min_value: 5
        row_condition: "order_id is not null"
        strictly: True
```

### audit_helper
Only for the dev env. 

An example using a test in this package. 
"analysis/audit_helper_compare_relation.sql":
```sql
{% set old_etl_relation = ref("orders__deprecated") %}
{% set dbt_relation = ref("orders") %}

{{ audit_helper.compare_relations(
    a_relation = old_etl_relation,
    b_relation = dbt_relation,
    primary_key = "order_id"
) }}

```

Preview the results. It shows percentage of match and mismatch. 

"macros/audit_helper_compare_column_values.sql":
```sql
{% macro audit_helper_compare_column_values() %}
    {% set columns_to_compare = adapter.get_columns_in_relation(ref('orders__deprecated')) %}

    {% set old_etl_relation_query %}
        select * from {{ ref('orders__deprecated') }}
    {% endset %}

    {% set new_etl_relation_query %}
        select * from {{ ref('orders') }}
    {% endset %}

    {% if execute %}
        {% for column in columns_to_compare %}
            {{ log('Comparing column "' ~ column.name ~'"', info=True) }}
            {% set audit_query = audit_helper.compare_column_values(
                a_query = old_etl_relation_query,
                b_query = new_etl_relation_query,
                primary_key = "order_id",
                column_to_compare = column.name
            ) %}

            {% set audit_result = run_query(audit_query) %}

            {% do log(audit_results.column_names, info=True) %}
            {% for row in audit_results.rows %}
                {% do log(row.values(), info=True) %}
            {% endfor %}
        {% endfor %}
    {% endif %}
{% endmacro %}
```

Run `dbt run-operation audit_helper_compare_column_values`, 














