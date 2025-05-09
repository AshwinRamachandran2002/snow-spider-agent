SELECT
  item.item_name AS Product_Name,
  SUM(item.quantity) AS Total_Quantity
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
WHERE
  _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  AND ecommerce.transaction_id IN (
    SELECT DISTINCT ecommerce.transaction_id
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item
    WHERE
      _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
      AND LOWER(item.item_name) = 'google navy speckled tee'
  )
  AND LOWER(item.item_name) <> 'google navy speckled tee'
GROUP BY
  Product_Name
ORDER BY
  Total_Quantity DESC
LIMIT 1;