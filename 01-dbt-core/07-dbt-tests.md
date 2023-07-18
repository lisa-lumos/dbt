# 7. dbt tests
There are 2 types of test in dbt - singular and generic. 

## Generic tests
4 dbt built-in generic tests:
- unique
- not_null
- accepted_values list
- relationships (foreign key references, etc)

Can also come from 3rd party packages. 

You can have one or multiple files for tests. 

In the "models" folder, create a file "models/schema.yml" (this file name is standard, but can be named differently):
```yml
version: 2

models: 
  - name: dim_listings_cleansed # model name
    columns: 
    - name: listing_id # col name
      tests: 
        - unique
        - not_null
```

Run `dbt test`:
```console
(venv) (base) lisa@mac16 dbtlearn % dbt test
21:40:12  Running with dbt=1.5.1
21:40:12  Found 8 models, 2 tests, 2 snapshots, 0 analyses, 321 macros, 0 operations, 1 seed file, 3 sources, 0 exposures, 0 metrics, 0 groups
21:40:12  
21:40:15  Concurrency: 1 threads (target='dev')
21:40:15  
21:40:15  1 of 2 START test not_null_dim_listings_cleansed_listing_id .................... [RUN]
21:40:17  1 of 2 PASS not_null_dim_listings_cleansed_listing_id .......................... [PASS in 1.93s]
21:40:17  2 of 2 START test unique_dim_listings_cleansed_listing_id ...................... [RUN]
21:40:18  2 of 2 PASS unique_dim_listings_cleansed_listing_id ............................ [PASS in 1.39s]
21:40:18  
21:40:18  Finished running 2 tests in 0 hours 0 minutes and 5.49 seconds (5.49s).
21:40:18  
21:40:18  Completed successfully
21:40:18  
21:40:18  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 TOTAL=2
```

Can see both tests have passed. "target/compiled/dbtlearn/models/schema.yml" folder contains compiled tests, which are sql commands that dbt runs behind the scene. If you a test did not pass, dbt will show the sql file's path that had an error. 

Similarly, add tests for other cols in the same file "models/schema.yml":
```yml
version: 2

models: 
  - name: dim_listings_cleansed # model name

    columns: 

    - name: listing_id # col name
      tests: 
        - unique
        - not_null
    
    - name: host_id # col name
      tests:
      - not_null
      - relationships: 
          to: ref('dim_hosts_cleansed') # note the indentation here has to be 4
          field: host_id
    
    - name: room_type # col name
      tests:
      - accepted_values:
          values: [ # note the indentation here has to be 4
            'Entire home/apt',
            'Private room',
            'Shared room',
            'Hotel room'
          ]
```

## Singular tests
SQL queries stored in "tests" folder. 

They expect to return nothing. If they returned anything, then the test is considered failing. 

Inside the "tests" folder, create a new file "tests/dim_listings_min_nights.sql":
```sql
select
  *
from
  {{ ref('dim_listings_cleansed') }}
where 
  minimum_nights < 1
limit 10
```

Run `dbt test`:
```console
(venv) (base) lisa@mac16 dbtlearn % dbt test
22:38:25  Running with dbt=1.5.1
22:38:25  Found 8 models, 6 tests, 2 snapshots, 0 analyses, 321 macros, 0 operations, 1 seed file, 3 sources, 0 exposures, 0 metrics, 0 groups
22:38:25  
22:38:27  Concurrency: 1 threads (target='dev')
22:38:27  
22:38:27  1 of 6 START test accepted_values_dim_listings_cleansed_room_type__Entire_home_apt__Private_room__Shared_room__Hotel_room  [RUN]
22:38:27  1 of 6 PASS accepted_values_dim_listings_cleansed_room_type__Entire_home_apt__Private_room__Shared_room__Hotel_room  [PASS in 0.84s]
22:38:27  2 of 6 START test dim_listings_min_nights ...................................... [RUN]
22:38:29  2 of 6 PASS dim_listings_min_nights ............................................ [PASS in 1.26s]
22:38:29  3 of 6 START test not_null_dim_listings_cleansed_host_id ....................... [RUN]
22:38:29  3 of 6 PASS not_null_dim_listings_cleansed_host_id ............................. [PASS in 0.67s]
22:38:29  4 of 6 START test not_null_dim_listings_cleansed_listing_id .................... [RUN]
22:38:30  4 of 6 PASS not_null_dim_listings_cleansed_listing_id .......................... [PASS in 0.64s]
22:38:30  5 of 6 START test relationships_dim_listings_cleansed_host_id__host_id__ref_dim_hosts_cleansed_  [RUN]
22:38:31  5 of 6 PASS relationships_dim_listings_cleansed_host_id__host_id__ref_dim_hosts_cleansed_  [PASS in 1.12s]
22:38:31  6 of 6 START test unique_dim_listings_cleansed_listing_id ...................... [RUN]
22:38:32  6 of 6 PASS unique_dim_listings_cleansed_listing_id ............................ [PASS in 1.16s]
22:38:32  
22:38:32  Finished running 6 tests in 0 hours 0 minutes and 7.50 seconds (7.50s).
22:38:32  
22:38:32  Completed successfully
22:38:32  
22:38:32  Done. PASS=6 WARN=0 ERROR=0 SKIP=0 TOTAL=6
```

To run a specific test, use `dbt test --select dim_listings_cleansed`. 
