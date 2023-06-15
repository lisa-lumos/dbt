# Analyses and seeds

## Analyses
Just sql files that lives in the "analyses" folder, that will not be built into anything. 
- Support Jinja
- Can be compiled `dbt compile`

Useful for:
- one off queries
- training queries
- auditing/refactoring

Can have version control, because it lives in the project. 

When you run `dbt compile`, you can see the compile queries in the "target" folder. 

When you run `dbt run`, the analyses will not run. 

## Seeds
csv files in the "seeds"/"data" folder, that becomes a table in the db when run `dbt seed`. 

Seeds are not designed for large, or frequently change data. 

Can have version control, because it lives in the project. 

Create tests and descriptions similar as models. 

Refer seeds like models. 