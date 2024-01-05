# 3. Resource configs and properties
Properties usually declare things about your project resources; configs usually go the extra step of telling dbt how to build those resources in your warehouse.

Depending on the resource type, configurations can be defined:
- Using a config() Jinja macro, within a model/snapshot/test ".sql" file
- Using a config property in a ".yml" file
- From the "dbt_project.yml" file, under the corresponding resource key

Some configs can be overridden, some can be additive:
- `tags` are additive. If a model has some tags configured in dbt_project.yml, and more tags applied in its .sql file, the final set of tags will include all of them.
- `meta` dictionaries are merged (a more specific key-value pair replaces a less specific value with the same key)
- `pre-hook`/`post-hook` are additive.

Resource path is the nested dictionary keys, that provide the path to a directory of that resource type, or a single instance of that resource type by its name.

## General properties
### columns
It is the child property of models/sources/seeds/snapshots/analyses. 

Tests can be applied to columns. 

### config
The child property of models/seeds/snapshots/tests/sources/metrics/exposures. 

### constraints
The platform will perform additional validation on data, as it is being populated in a new table, or inserted into a preexisting table. If the validation fails, the table creation or update fails, the operation is rolled back, and you will see an error message.

Can apply PK, expression, unique, not null, foreign_key, etc. 

### deprecation_date
Provides a mechanism to communicate plans and timelines for long-term support and maintenance, and to facilitate change management.

### description
A user-defined description. 

### latest_version
The latest version of this model.

### include
The specification of which columns are defined in a model's top-level columns property, to include or exclude in a versioned implementation of that model.

### quote
Used to enable or disable quoting for column names.

### Data tests
Defines assertions about a column, table, or view. 

Generic tests: not_null, unique, accepted_values, relationships. 

Can apply to a expression. 

Can use custom generic test. 

### versions
skipped. 

## General configs
### access
The access level of the model.

private/protected/public. 

### alias
A custom alias for a model/seed/snapshot/test

### database


### enabled


### full_refresh


### contract


### grants


### group


### docs


### persist_docs


### pre-hook & post-hook


### schema


### tags


### meta


### Advanced usage


### Using the + prefix




## For models



## For seeds



## For snapshots



## For tests



## For sources



## For analyses



## For exposures



## For macros


































