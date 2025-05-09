-- Top-companion product by total quantity bought together with the
-- “Google Navy Speckled Tee” in December 2020
SELECT
  i.item_name  AS top_companion_product,
  SUM(i.quantity) AS total_quantity_with_tee
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`  e,
     UNNEST(e.items) AS i
WHERE _TABLE_SUFFIX LIKE '202012%'          -- December-2020 partitions
  AND e.event_name = 'purchase'             -- only purchase events
  -- only transactions that include the Google Navy Speckled Tee
  AND e.ecommerce.transaction_id IN (
        SELECT DISTINCT ecommerce.transaction_id
        FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
             UNNEST(items) AS j
        WHERE _TABLE_SUFFIX LIKE '202012%'
          AND event_name = 'purchase'
          AND j.item_name = 'Google Navy Speckled Tee')
  -- exclude the Tee itself when counting companion items
  AND i.item_name <> 'Google Navy Speckled Tee'
GROUP BY i.item_name
ORDER BY total_quantity_with_tee DESC
LIMIT 1;