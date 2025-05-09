SELECT
  i.`item_name`,
  SUM(i.`quantity`) AS total_quantity
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
CROSS JOIN UNNEST(e.`items`) AS i
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'          -- December-2020 data
  AND e.`event_name` = 'purchase'                              -- consider only purchases
  AND EXISTS (                                                 -- transactions that include the tee
        SELECT 1
        FROM UNNEST(e.`items`) it
        WHERE it.`item_name` = 'Google Navy Speckled Tee'
      )
  AND i.`item_name` <> 'Google Navy Speckled Tee'              -- exclude the tee itself
GROUP BY i.`item_name`
ORDER BY total_quantity DESC
LIMIT 1;