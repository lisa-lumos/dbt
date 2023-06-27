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

















