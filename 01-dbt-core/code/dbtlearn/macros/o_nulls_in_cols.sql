{% macro no_nulls_in_cols(model) %} -- the function takes a model
  select 
    * 
  from 
    {{ model }} 
  where
    {% for col in adapter.get_columns_in_relation(model) -%} -- adapter.get_columns_in_relation is a dbt built-in functionality. "-" at the end means trim off following white spaces, to get a one-line expression
    {{ col.column }} is null or -- if col1 is null or col2 is null or col3 is null or... (loop over all col names)
    {% endfor %}
    false -- to match the last/redundant "or" in the loop
{% endmacro %}