# Debugging tests
### Great expectations intro
A library for data testing. Upstream data can change any time, you need to make sure they are as you expected. If the data is not correct, you should know it first, instead of the consumers of your dashboards. 

The dbt package that corresponds with Great Expectations is dbt-expectations: https://github.com/calogica/dbt-expectations. 

There are tests that you can add to yml files, such as:
- expect current model to have same num of rows as another model
- expect for a col, a certain % of values in it to be in a certain min/max range
- expect for a col, the max val to be between a min/max range
- expect for a col, the data type to be a certain data type
- expect num of distinct vals in a col to be a given value
- expect col vals to match a regex
- ...

All these tests can take config vals of error/warn. 

Note that regex first need to pass jinja, then need to pass snowflake, then winds down to the final regex. 
