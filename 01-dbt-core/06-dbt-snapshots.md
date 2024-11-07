# 6. dbt snapshots
SCD type 2 in dbt: "dbt_valid_from" and "dbt_valid_to" cols indicate how historical records are active during which time span. If "dbt_valid_to" is null, that means the record is most current. 

You can use either of the strategies: 
- A unique key, and an updated_at field
- Any change in a set of cols, or all cols, will be picked up as an update

Snapshots live in the "snapshots" folder, which can be verified in the "dbt_project.yml" file. 

Here we create two snapshots, one for raw_listings and one for raw_hosts. 

In "snapshots" folder, create a new file "snapshots/scd_raw_listings.sql":
```sql
{% snapshot scd_raw_listings %} -- snapshot table name
{{
  config(
    target_schema='dev',
    unique_key='id',
    strategy='timestamp', -- which strategy to use
    updated_at='updated_at',
    invalidate_hard_deletes=True -- make sure to pick up deletes, and seal it with the correct timestamp of deletion
  )
}}

select * 
from {{ source('airbnb', 'listings') }}

{% endsnapshot %}
```

Run `dbt snapshot` to create the initial snapshot, and see the "airbnb.dev.scd_raw_listings" table. 
```console
(venv) (base) lisa@mac16 dbtlearn % dbt snapshot
19:41:46  Running with dbt=1.5.1
19:41:47  Found 8 models, 0 tests, 1 snapshot, 0 analyses, 321 macros, 0 operations, 1 seed file, 3 sources, 0 exposures, 0 metrics, 0 groups
19:41:47  
19:41:50  Concurrency: 1 threads (target='dev')
19:41:50  
19:41:50  1 of 1 START snapshot dev.scd_raw_listings ..................................... [RUN]
19:41:53  1 of 1 OK snapshotted dev.scd_raw_listings ..................................... [success in 2.49s]
19:41:53  
19:41:53  Finished running 1 snapshot in 0 hours 0 minutes and 6.00 seconds (6.00s).
19:41:53  
19:41:53  Completed successfully
19:41:53  
19:41:53  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

Note the new cols in this "scd_raw_listings" table - "dbt_valid_from" col have same val as "dbt_updated_at", and "dbt_valid_to" col all have NULLs. 

If we make an update to the raw table from Snowflake:
```sql
update airbnb.raw.raw_listings 
set 
  minimum_nights = 30,
  updated_at = current_timestamp() 
where id = 3176
;
```

And run `dbt snapshot` to update the snapshot, then in Snowflake run `select * from airbnb.dev.scd_raw_listings where id=3176;`, we can then see these 2 records:
```
ID    ...  UPDATED_AT               DBT_SCD_ID                        DBT_UPDATED_AT           DBT_VALID_FROM           DBT_VALID_TO
3176  ...  2023-06-07 12:47:13.948  fa6d509ef4e446916277df0a755c73ac  2023-06-07 12:47:13.948  2023-06-07 12:47:13.948  NULL
3176  ...  2009-06-05 21:34:42.000  c9e3bc0b5eb3a808ee31530eccdfa503  2009-06-05 21:34:42.000	 2009-06-05 21:34:42.000  2023-06-07 12:47:13.948
```

Behind the scene, this is a merge statement against the snapshot table, run by dbt. 

Similarly, create "snapshots/scd_raw_hosts.sql":
```sql
{% snapshot scd_raw_hosts %}

{{
  config(
    target_schema='dev',
    unique_key='id',
    strategy='timestamp',
    updated_at='updated_at',
    invalidate_hard_deletes=true
  )
}}

select * 
from {{ source('airbnb', 'hosts') }}

{% endsnapshot %}
```

And run `dbt snapshot`. 
