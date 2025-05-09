SELECT item.item_name AS Product_Name, SUM(IFNULL(item.quantity, 1)) AS Total_Quantity
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS t,
UNNEST(t.items) AS item
WHERE t.event_timestamp IN (
  SELECT DISTINCT t_sub.event_timestamp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS t_sub,
  UNNEST(t_sub.items) AS item_sub
  WHERE item_sub.item_name = 'Google Navy Speckled Tee'
  AND t_sub.event_date BETWEEN '20201201' AND '20201231'
)
AND item.item_name != 'Google Navy Speckled Tee'
AND t.event_date BETWEEN '20201201' AND '20201231'
GROUP BY item.item_name
ORDER BY Total_Quantity DESC
LIMIT 1;