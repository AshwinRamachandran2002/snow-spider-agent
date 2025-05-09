SELECT DISTINCT
  e.ecommerce.transaction_id,
  e.ecommerce.total_item_quantity,
  e.ecommerce.purchase_revenue_in_usd
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e,
  UNNEST(e.items) AS item
WHERE
  e.event_date = '20201130'
  AND e.ecommerce.transaction_id IS NOT NULL
  AND e.ecommerce.total_item_quantity IS NOT NULL
  AND e.ecommerce.purchase_revenue_in_usd IS NOT NULL
  AND item.item_category = (
    SELECT item_category FROM (
      SELECT
        item.item_category,
        SUM(e.ecommerce.tax_value_in_usd) / SUM(e.ecommerce.purchase_revenue_in_usd) AS tax_rate
      FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130` AS e,
        UNNEST(e.items) AS item
      WHERE
        e.event_date = '20201130'
        AND item.item_category IS NOT NULL
        AND e.ecommerce.tax_value_in_usd IS NOT NULL
        AND e.ecommerce.purchase_revenue_in_usd IS NOT NULL
        AND e.ecommerce.purchase_revenue_in_usd > 0
      GROUP BY
        item.item_category
      HAVING
        SUM(e.ecommerce.purchase_revenue_in_usd) > 0
      ORDER BY
        tax_rate DESC
      LIMIT 1
    )
  )