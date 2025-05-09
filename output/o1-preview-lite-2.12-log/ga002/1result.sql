WITH customers_per_month AS (
  SELECT 
    DISTINCT user_pseudo_id,
    FORMAT_DATE('%b-%Y', PARSE_DATE('%Y%m%d', event_date)) AS Month
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
  WHERE item.item_name = 'Google Red Speckled Tee'
    AND event_date BETWEEN '20201101' AND '20210131'
),
purchases_per_month AS (
  SELECT 
    FORMAT_DATE('%b-%Y', PARSE_DATE('%Y%m%d', t1.event_date)) AS Month,
    item.item_name AS Product_Name,
    SUM(item.quantity) AS Quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS t1,
  UNNEST(t1.items) AS item
  JOIN customers_per_month AS c
    ON t1.user_pseudo_id = c.user_pseudo_id
    AND FORMAT_DATE('%b-%Y', PARSE_DATE('%Y%m%d', t1.event_date)) = c.Month
  WHERE item.item_name != 'Google Red Speckled Tee'
    AND item.item_name IS NOT NULL
    AND item.item_name != '(not set)'
    AND t1.event_date BETWEEN '20201101' AND '20210131'
  GROUP BY Month, Product_Name
),
ranked_products AS (
  SELECT 
    Month,
    Product_Name,
    Quantity,
    ROW_NUMBER() OVER (PARTITION BY Month ORDER BY Quantity DESC) AS rn
  FROM purchases_per_month
)
SELECT Month, Product_Name, Quantity
FROM ranked_products
WHERE rn = 1
ORDER BY Month;