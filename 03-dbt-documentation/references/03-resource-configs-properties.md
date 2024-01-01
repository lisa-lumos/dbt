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



## General configs



## For models



## For seeds



## For snapshots



## For tests



## For sources



## For analyses



## For exposures



## For macros


































