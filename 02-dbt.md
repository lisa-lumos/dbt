# dbt

## dbt Overview
dbt transforms data in the DWH with SQL select statements. It will deploy your analytics code following software engineering best practices, like modularity, portability, CICD, testing and documentation. You will write your code an compile it to sql and execute it, the transformations are version controlled. It allow you to create different environments like dev and prod, and easily switch between them. In terms of performance, dbt will take your models, understand the dependencies between them, and will create a dependency order and parallelize the way your models are built. 

## Use case and Input data model Overview
Suppose you are a analytics engineer in Airbnb that is responsible for all the data flow in Berlin, Germany and Europe. You need to import your data into a data warehouse, cleanse and expose the data to a BI tool. You will also need to write test, automation and documentation. Our data source is Airbnb's data sharing site `insideairbnb.com/berlin/`. 

The requirements 
- Modeling changes are easy to follow and revert
- Explicit dependencies between models, so the framework knows in which order to execute different steps in the pipeline; also these dependencies need to be easy to explore and overview
- Data quality tests
- Error reporting
- Track history of dimension tables, for new records, and slowly changing dimensions
- Easy-to-access documentation



























