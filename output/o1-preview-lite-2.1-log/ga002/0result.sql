WITH red_speckled_tee_buyers AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(items) AS item
  WHERE LOWER(item.item_name) = 'google red speckled tee'
    AND event_date BETWEEN '20201101' AND '20210131'
),
monthly_totals AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', event_date)) AS month,
    item.item_name,
    SUM(item.quantity) AS total_quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(items) AS item
  JOIN red_speckled_tee_buyers USING(user_pseudo_id)
  WHERE event_date BETWEEN '20201101' AND '20210131'
    AND LOWER(item.item_name) != 'google red speckled tee'
  GROUP BY month, item.item_name
),
ranked_totals AS (
  SELECT
    month,
    item_name AS Product_Name,
    total_quantity AS Quantity,
    ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_quantity DESC) AS rn
  FROM monthly_totals
)
SELECT
  CASE month
    WHEN 11 THEN 'Nov-2020'
    WHEN 12 THEN 'Dec-2020'
    WHEN 1 THEN 'Jan-2021'
  END AS Month,
  Product_Name,
  Quantity
FROM ranked_totals
WHERE rn = 1
ORDER BY month;