WITH red_tee_customers AS (
  SELECT DISTINCT
    EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', e.event_date)) AS year,
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', e.event_date)) AS month,
    e.user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  JOIN UNNEST(e.items) AS i
  WHERE e.event_name = 'purchase'
    AND i.item_name = 'Google Red Speckled Tee'
    AND e.event_date BETWEEN '20201101' AND '20210131'
),
other_products AS (
  SELECT
    EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', e.event_date)) AS year,
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', e.event_date)) AS month,
    i.item_name,
    SUM(i.quantity) AS total_quantity
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  JOIN UNNEST(e.items) AS i
  JOIN red_tee_customers rtc
    ON e.user_pseudo_id = rtc.user_pseudo_id
    AND EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', e.event_date)) = rtc.year
    AND EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', e.event_date)) = rtc.month
  WHERE e.event_name = 'purchase'
    AND i.item_name != 'Google Red Speckled Tee'
    AND e.event_date BETWEEN '20201101' AND '20210131'
  GROUP BY year, month, i.item_name
),
ranked_products AS (
  SELECT
    year,
    month,
    item_name,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY total_quantity DESC) AS rn
  FROM other_products
)
SELECT
  FORMAT_DATE('%b-%Y', DATE(year, month, 1)) AS Month,
  item_name AS Product_Name,
  total_quantity AS Quantity
FROM ranked_products
WHERE rn = 1
ORDER BY year, month;