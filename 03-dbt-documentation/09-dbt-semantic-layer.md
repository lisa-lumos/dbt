# 9. dbt Semantic Layer
## About the dbt Semantic Layer
The dbt Semantic Layer eliminates duplicate coding, by allowing data teams to define metrics on top of existing models and automatically handles data joins.

## Get started with the dbt Semantic Layer
MetricFlow allows you to define metrics in your dbt project, and query them whether in dbt Cloud, or dbt Core, with MetricFlow commands.

To query those metrics in downstream tools, you'll need a dbt Cloud Team or Enterprise account.

Semantic models consist of entities (all sorts of keys), dimensions, and measures.

It's best practice to create semantic models in the "/models/semantic_models" directory in your project. 

You can define metrics in the same YAML files as your semantic models, or create a new file. If you want to create your metrics in a new file, create another directory called "/models/metrics". 

The dbt Semantic Layer is proprietary; however, some components of the dbt Semantic Layer are open source, such as dbt-core and MetricFlow. dbt Cloud Developer or dbt Core users can define metrics in their project. However, to experience the universal dbt Semantic Layer and access those metrics using the API or downstream tools, users must be on a dbt Cloud Team, or Enterprise plan.

MetricFlow does not support pass-through rendering of Jinja macros, so we can't reference MetricFlow queries inside of dbt models. See Metrics as the leaf node of your DAG, and a place for users to consume metrics.

## Set up your Semantic Layer
skipped. 

## Architecture
The dbt Semantic Layer allows you to define metrics, and use various interfaces to query them. The Semantic Layer does the heavy lifting to find where the queried data exists in your data platform, and generates the SQL (including joins) to make the request.

Semantic Layer APIs: The interfaces allow users to submit metric queries using GraphQL and JDBC APIs. They also serve as the foundation, for building first-class integrations with various tools.	

## Integrations
### Available integrations
Tableau, Google Sheets, Hex, ...

### Google Sheets (beta)
skipped

### Tableau (beta)
skipped
