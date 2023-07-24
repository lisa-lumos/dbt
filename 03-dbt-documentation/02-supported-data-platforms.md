# 2. Supported data platforms
dbt connects with data platforms, by using a dedicated adapter plugin for each.

Plugins are built as Python modules, that dbt Core discovers, if they are installed on your system.

You can connect to data platforms, either directly in the dbt Cloud UI, or install them manually using the CLI. 

There are two types of adapters:
- Verified - dbt Labs' strict adapter program assures users of trustworthy/tested/regularly-updated adapters, for production use. Verified adapters earn a "Verified" status, providing users with trust and confidence.
- Community - Community adapters are open-source, and maintained by community members.

Verified adapters:
- AlloyDB
- BigQuery
- Databricks
- Dremio
- Postgres
- Redshift
- Snowflake
- Spark
- Starburst/Trino
- Fabric Synapse
- Azure Synapse

## How to connect to adapters
Using 
- dbt cloud UI. Supports data platforms that are verified and maintained by dbt Labs, or partners.
- CLI, such as `pip install dbt-snowflake`. 

## Community adapters
Adapter plugins, contributed and maintained by members of the community.

Data platforms:
Athena	Greenplum	Oracle 
Clickhouse	Hive	Rockset 
IBM DB2	Impala	SingleStore 
Doris & SelectDB	Infer	SQLite 
DuckDB	iomete	SQL Server & Azure SQL 
Dremio	Layer	Teradata 
Exasol Analytics	Materialize	TiDB 
Firebolt	MindsDB	Vertica 
AWS Glue	MySQL	
Databend Cloud	fal - Python models	

## Contribute to adapters
skipped. 
