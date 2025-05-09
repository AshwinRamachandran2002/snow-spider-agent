SELECT item.item_name AS Product_Name, SUM(item.quantity) AS Total_Quantity
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS e
JOIN UNNEST(e.items) AS item
WHERE e.event_name = 'purchase'
  AND e.event_date BETWEEN '20201201' AND '20201231'
  AND EXISTS (
    SELECT 1 FROM UNNEST(e.items) AS i WHERE i.item_name = 'Google Navy Speckled Tee'
  )
  AND item.item_name != 'Google Navy Speckled Tee'
GROUP BY item.item_name
ORDER BY Total_Quantity DESC
LIMIT 1;