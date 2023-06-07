select 
  * 
from 
  {{ ref('dim_listings_cleansed') }} l
  inner join 
  {{ ref('fct_reviews') }} r
  using (listing_id)
where l.created_at >= r.review_date