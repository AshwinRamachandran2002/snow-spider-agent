-- Task: On November 30, 2020, for purchase events, calculate the tax rate for each item category by dividing the total tax value in USD by the total purchase revenue in USD per item category. Identify the item category with the highest tax rate. Then, for that item category, retrieve the transaction IDs, total item quantities, total purchase revenue in USD, and total purchase revenue for those purchase events where the item category matches, grouping the results by transaction ID.

WITH top_category AS (
  SELECT
    product.item_category,
    SUM(ecommerce.tax_value_in_usd) / SUM(ecommerce.purchase_revenue_in_usd) AS tax_rate
  FROM
    bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130,
    UNNEST(items) AS product
  WHERE
    event_name = 'purchase'
  GROUP BY
    product.item_category
  ORDER BY
    tax_rate DESC
  LIMIT 1
)

SELECT
    ecommerce.transaction_id,
    SUM(ecommerce.total_item_quantity) AS total_item_quantity,
    SUM(ecommerce.purchase_revenue_in_usd) AS purchase_revenue_in_usd,
    SUM(ecommerce.purchase_revenue) AS purchase_revenue
FROM
    bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130, 
    UNNEST(items) AS product
JOIN top_category
ON product.item_category = top_category.item_category
WHERE
    event_name = 'purchase'
GROUP BY
    ecommerce.transaction_id;