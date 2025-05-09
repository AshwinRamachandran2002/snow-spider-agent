WITH tee_buyers AS (
  -- customers who bought “Google Red Speckled Tee” (month-tagged)
  SELECT DISTINCT
         user_pseudo_id,
         FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS yr_mo
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(items) AS i
  WHERE event_name = 'purchase'
    AND LOWER(i.item_name) LIKE '%google%red%speckled%tee%'
    AND _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'      -- Nov-20 to Jan-21
),
other_purchases AS (
  -- “other” items bought by those customers in the same month
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', e._TABLE_SUFFIX)) AS yr_mo,
    i.item_name,
    SUM(i.quantity) AS qty
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  JOIN tee_buyers b
    ON e.user_pseudo_id = b.user_pseudo_id
   AND FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', e._TABLE_SUFFIX)) = b.yr_mo
  CROSS JOIN UNNEST(e.items) AS i
  WHERE e.event_name = 'purchase'
    AND LOWER(i.item_name) NOT LIKE '%google%red%speckled%tee%'   -- exclude the tee itself
    AND e._TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY yr_mo, i.item_name
),
ranked AS (
  SELECT
    yr_mo,
    item_name,
    qty,
    ROW_NUMBER() OVER (PARTITION BY yr_mo ORDER BY qty DESC) AS rn
  FROM other_purchases
)
-- top-selling “other” item per month (Nov-20, Dec-20, Jan-21)
SELECT
  yr_mo,
  item_name,
  qty
FROM ranked
WHERE rn = 1
ORDER BY yr_mo;