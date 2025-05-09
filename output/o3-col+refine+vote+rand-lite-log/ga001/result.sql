-- Product most frequently bought together with the Google Navy Speckled Tee
SELECT
  i2.item_name   AS top_companion_product,
  SUM(i2.quantity) AS total_quantity
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS e
     -- first unnest to find the Navy Speckled Tee in each purchase event
     , UNNEST(e.items) AS i1
     -- unnest again to capture every other item in those same events
     , UNNEST(e.items) AS i2
WHERE e._TABLE_SUFFIX BETWEEN '01' AND '31'      -- December-2020 tables
  AND e.event_name = 'purchase'                  -- only purchase events
  AND LOWER(i1.item_name) LIKE '%google%navy%speckled%tee%'  -- events containing the tee
  AND LOWER(i2.item_name) NOT LIKE '%google%navy%speckled%tee%' -- exclude the tee itself
GROUP BY top_companion_product
ORDER BY total_quantity DESC
LIMIT 1;