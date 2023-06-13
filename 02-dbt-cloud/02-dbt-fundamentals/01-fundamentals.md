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


## Tests


## Documentation


## Deployment



## References
- https://courses.getdbt.com/courses/fundamentals
