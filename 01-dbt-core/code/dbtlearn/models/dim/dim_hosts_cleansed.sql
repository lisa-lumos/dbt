{{
  config(materialized = 'view')
}}

with src_hosts as (
  select
    *
  from
    {{ ref('src_hosts') }}
)
select
  host_id,
  nvl(host_name, 'anonymous') as host_name, -- replace nulls with anonymous
  is_superhost,
  created_at,
  updated_at
from
  src_hosts