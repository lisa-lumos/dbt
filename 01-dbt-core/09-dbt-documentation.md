# 9. dbt documentation
The general idea of documentation in dbt, is to keep them as close to the actual source as possible, to prevent your documentation and your analytics code from diverging. 

Documentation can be defined in:
- yaml files, like "schema.yml"
- standalone markdown files

dbt ships with a lightweight documentation web server. The landing page uses the "overview.md" file. You can add your own assets, like images, to a special project folder and refer to them. 

## Basic docs
Can live in yml files. Such as "models/schema.yml": 

```yml
version: 2

models: 
  - name: dim_listings_cleansed # model name
    description: Cleansed table which contains Airbnb listings # for basic docs

    columns: 

    - name: listing_id # col name
      description: Primary key for the listing # for basic docs
      tests: 
        - unique
        - not_null
    
    - name: host_id # col name
      description: the hosts' id. References the host table. # for basic docs
      tests:
      ...
```

Run `dbt docs generate`, dbt will generate an html doc, in the "target" folder:
```console
(venv) (base) lisa@mac16 dbtlearn % dbt docs generate
02:43:40  Running with dbt=1.5.1
02:43:41  Found 8 models, 9 tests, 2 snapshots, 0 analyses, 437 macros, 0 operations, 1 seed file, 3 sources, 0 exposures, 0 metrics, 0 groups
02:43:41  
02:43:42  Concurrency: 1 threads (target='dev')
02:43:42  
02:43:43  Building catalog
02:43:46  Catalog written to /Users/lisa/Desktop/dbt/01-dbt-core/code/dbtlearn/target/catalog.json

(venv) (base) lisa@mac16 dbtlearn % cd target

(venv) (base) lisa@mac16 target % ls -lrth
total 4920
-rw-r--r--  1 lisa  staff   1.0K Jun  6 21:26 sources.json
drwxr-xr-x@ 3 lisa  staff    96B Jul  6 20:27 compiled
drwxr-xr-x@ 3 lisa  staff    96B Jul  6 20:27 run
-rw-r--r--  1 lisa  staff   470K Jul  6 20:43 partial_parse.msgpack
-rw-r--r--  1 lisa  staff    20K Jul  6 20:43 graph.gpickle
-rw-r--r--  1 lisa  staff   8.8K Jul  6 20:43 run_results.json
-rw-r--r--  1 lisa  staff   1.4M Jul  6 20:43 index.html
-rw-r--r--  1 lisa  staff    12K Jul  6 20:43 catalog.json
-rw-r--r--  1 lisa  staff   475K Jul  6 20:43 manifest.json

(venv) (base) lisa@mac16 target % cat catalog.json 
{"metadata": {"dbt_schema_version": "https://schemas.getdbt.com/dbt/catalog/v1.json", "dbt_version": "1.5.1", "generated_at": "2023-07-07T02:43:46.434546Z", "invocation_id": "5f9221fb-0874-4ee0-ae65-e6a8c3cdca92", "env": {}}, "nodes": {"model.dbtlearn.dim_listings_cleansed": {"metadata": {"type": "VIEW", "schema": "DEV", "name": "DIM_LISTINGS_CLEANSED", ...
```

You can add the files in the folder to a static web server. Or you can use a lightweight dbt library server:
```console
(venv) (base) lisa@mac16 target % cd .. 

(venv) (base) lisa@mac16 dbtlearn % ls
README.md	dbt_project.yml	models		snapshots
analyses	logs		packages.yml	target
dbt_packages	macros		seeds		tests
(venv) (base) lisa@mac16 dbtlearn % dbt docs serve
02:49:31  Running with dbt=1.5.1
Serving docs at 8080
To access from your browser, navigate to: http://localhost:8080

Press Ctrl+C to exit.
```
And the docs webpage will open in your default browser. 

## Markdown-based docs
"models/schema.yml":
```yml
version: 2

models: 
  - name: dim_listings_cleansed # model name
    description: Cleansed table which contains Airbnb listings # for basic docs

    columns: 

    ...

    - name: minimum_nights # col name
      description: '{{ doc("dim_listing_cleansed__minimum_nights") }}' # for markdown docs, refers to the documentation key
      tests:
        - positive_val
```

"models/docs.md" (or other file name in this folder):
```md
{% docs dim_listing_cleansed__minimum_nights %}
Minimum number of nights required to rent this property. 

Keep in mind that old listings might have `minimum_nights` set to 0 in the source tables. Our cleaning algorithm updates this to `1`. 

{% enddocs %}
```

The documentation key name is up to you. 

Run `dbt docs generate`, then `dbt docs serve` to see the effect for this col of this table. 

## Redesign the overview page in docs
"models/overview.md":
```md
{% docs __overview__ %}
# Airbnb pipeline
Hi, welcome to the Airbnb pipeline documentation!

Here is the schema of our input data:
![input schema](https://dbtlearn.s3.us-east-2.amazonaws.com/input_schema.png)

{% enddocs %}
```

Notice the special tag `__overview__`. An image from s3 bucket was attached in there. 

## Include assets such as images to docs
Create a new folder "assets". "dbt_project.yml", associate the folder with the project:
```yml
...
asset-paths: ["assets"]
...
```

Download this image from s3 to the "assets" folder:
```console
(venv) (base) lisa@mac16 dbtlearn % curl https://dbtlearn.s3.us-east-2.amazonaws.com/input_schema.png -o assets/input_schema.png
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 66943  100 66943    0     0  88710      0 --:--:-- --:--:-- --:--:-- 89019
```

"models/overview.md":
```md
{% docs __overview__ %}
# Airbnb pipeline
Hi, welcome to the Airbnb pipeline documentation!

Here is the schema of our input data:
![input schema](assets/input_schema.png)

{% enddocs %}
```

An image from the "assets" folder was attached in there. 

When `dbt docs generate`, the whole assets folder will be copied to target folder, and will be referred by the html. You can also see it `http://localhost:8080/assets/` there in the browser. 

## The Lineage graph (data flow DAG)
A part of the docs. Sources are in green boxes, the rest are in blue. On the bottom left, you can select which resources to view. 

You can select which lineage to display, for example, `+src_hosts+` means to show all upstream models that `src_hosts` depends on, and all downstream models that depend on `src_hosts`. You can also use similar symbols for dbt run. 

