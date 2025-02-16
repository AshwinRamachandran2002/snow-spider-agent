-- Task: List all distinct users who bought 'Google Red Speckled Tee' in each of the three months starting from November 2020. Limit the output to the first 100 records.

WITH
  Params AS (
    SELECT 'Google Red Speckled Tee' AS selected_product
  ),
  DateRanges AS (
    SELECT '20201101' AS start_date, '20201130' AS end_date, '202011' AS period UNION ALL
    SELECT '20201201', '20201231', '202012' UNION ALL
    SELECT '20210101', '20210131', '202101'
  ),
  PurchaseEvents AS (
    SELECT
      period,
      user_pseudo_id,
      items
    FROM
      DateRanges
    JOIN
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
      ON _TABLE_SUFFIX BETWEEN start_date AND end_date
    WHERE
      event_name = 'purchase'
  ),
  ProductABuyers AS (
    SELECT DISTINCT
      period,
      user_pseudo_id
    FROM
      Params,
      PurchaseEvents,
      UNNEST(items) AS items
    WHERE
      items.item_name = selected_product
  )
SELECT
  period,
  user_pseudo_id
FROM
  ProductABuyers
LIMIT 100;