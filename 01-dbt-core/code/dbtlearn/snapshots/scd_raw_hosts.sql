{% snapshot scd_raw_hosts %}

{{
  config(
    target_schema='DEV',
    unique_key='id',
    strategy='timestamp',
    updated_at='updated_at',
    invalidate_hard_deletes=true
  )
}}
-- note that the 'DEV' is capitalized, because docs recognize the captilization. It doesn't affect the snowflake data part. 

select 
  * 
from 
  {{ source('airbnb', 'hosts') }}

{% endsnapshot %}