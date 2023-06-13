# dbt fundamentals
## Analytics Engineer
In a traditional team, data engineers build data infrastructure, doing ETL, etc; data analysts does reporting, build dashboards, etc. These two roles have gaps: the analysts knows what to build, engineers knows how to build it - Analytics engineer fills this gap. 

Cloud-based data warehouses couples the database and powerful compute, which changes ETL to ELT, and transform the data right in the warehouse. Able to scale. 

Analytics engineer is focused on taking the raw data, transform it, so analysts can consume it (The T in ELT). While data engineers does the EL in ELT.  

At a small company, a data team of one may own all three of these roles and responsibilities. As your team grows, the lines between these roles will remain blurry.

dbt is handles the T layer of the ELT for data platforms. dbt creates a connection to a data platform, and runs SQL code against the warehouse to transform data. 

## dbt Could setup
- dbt Cloud is a hosted version that streamlines development with an online IDE, and an interface to run dbt on a schedule.
- dbt Core is a command line tool that can be run locally.

## Models
In dbt Cloud IDE, you can: 
- Click "Preview" button to view the data results without building anything in the warehouse
- Click "compile" button and view the actual query that would be run against the data warehouse. 
- When you run `dbt run`, in the output, when you expand each model, you can see the query that was actually ran against the warehouse

Modularity: a system's components can be separated/recombined, with the benefit of flexibility/variety.

Model building conventions:
- Source tables (`src`): raw tables. 
- Staging models (`stg`): should be built one-to-one with the raw tables. 
- Intermediate models (`int`): between staging and final models, always built on staging models
- Fact models (`fct`): things that are occurring/occurred, such as events/clicks/...
- Dimension models (`dim`): what things are, such as users/products/customer/...

## Sources
If source table changes name/schema, you have to otherwise redirect in all models that refers to it. dbt put all locations of raw tables into a yaml file, and all other models can refer to its alias in yaml file. 

dbt sources also allow you to visualize raw tables (green in color) in your lineage. 

You can use `dbt source freshness` to check the freshness of raw tables.

## Tests
Scale your manual testing to development/deployment. 

`dbt run` would run all models, even if a test fails for a model somewhere. But `dbt build` would start from the beginning and run down the dependencies one by one, doing "run", followed by "test" for each model, so if one of the upstream test fails, it will not continue downstream. 

Tests can be run against your current project using a range of commands:
- `dbt test` runs all tests in the dbt project
- `dbt test --select test_type:generic`
- `dbt test --select test_type:singular`
- `dbt test --select one_specific_model`

In production, dbt Cloud can be scheduled to run `dbt test`. The "Run History" tab provides a interface for viewing the test results.

## Documentation
Strong documentation empowers users to self-service questions about data, and enables new team members to on-board quickly. Docs should be as automated as possible, and happen as close as possible to the coding.

In dbt, YML files document models, and they live in the same folder/subfolder as the models they document.

For models, descriptions can happen at the model, source, or column level.

How: 
- One-liner descriptions, such as `description: The primary key for customers.` 
- description blocks using markdown file, such as `description: '{{ doc("order_status") }}'`, with "models/staging/jaffle_shop/jaffle_shop.md":
```
{% docs order_status %}
	
One of the following values: 

| status         | definition                                       |
|----------------|--------------------------------------------------|
| placed         | Order placed, not yet shipped                    |
| shipped        | Order has been shipped, not yet been delivered   |
| completed      | Order has been received by customers             |
| return pending | Customer indicated they want to return this item |
| returned       | Item has been returned                           |

{% enddocs %}
```

`dbt docs generate` will use these to generate docs, which include
- Lineage Graph
- Model/source/column descriptions
- Generic tests added to a column
- Underlying SQL code, for each model
- ...


## Deployment
Means running a set of dbt commands, on a schedule. 

Deployment has a dedicated prod branch (the default, main/master), and a dedicated prod schema, such as `dbt_production`. 

The use of dev environments/branches makes it possible to continue to build your dbt project, without affecting the models/tests/documentation that are running in production.

When deploying a real dbt Project, you should set up a separate data warehouse account for this run. This should not be the same account that you personally use in development. The schema used in production should be different from anyone's development schema.

A single job can run multiple dbt commands. 

## References
- https://courses.getdbt.com/courses/fundamentals
