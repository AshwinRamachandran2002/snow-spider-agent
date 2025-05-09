/* Top‑quantity product bought together with “Google Navy Speckled Tee”
   in purchase events during December 2020                                   */
SELECT
  other.item_name                          AS other_product,
  SUM(COALESCE(other.quantity,0))          AS total_quantity
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
CROSS JOIN UNNEST(e.items) AS other
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'     -- December 2020 tables
  AND e.event_name = 'purchase'                           -- purchase events only
  -- keep only purchases that contain the tee
  AND EXISTS (
        SELECT 1
        FROM UNNEST(e.items) AS tee
        WHERE LOWER(tee.item_name) LIKE '%google navy speckled tee%'
      )
  -- exclude the tee itself when counting companions
  AND LOWER(other.item_name) NOT LIKE '%google navy speckled tee%'
GROUP BY other_product
ORDER BY total_quantity DESC
LIMIT 1;