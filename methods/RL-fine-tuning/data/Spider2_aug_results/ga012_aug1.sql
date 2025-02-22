-- Task: On November 30, 2020, identify the item category with the highest tax rate by dividing tax value in USD by purchase revenue in USD for purchase events.

SELECT
    product.`item_category`,
    SUM(ecommerce.`tax_value_in_usd`) / SUM(ecommerce.`purchase_revenue_in_usd`) AS `tax_rate`
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`,
    UNNEST(`items`) AS product
WHERE
    `event_name` = 'purchase'
GROUP BY
    product.`item_category`
ORDER BY
    `tax_rate` DESC
LIMIT 1;