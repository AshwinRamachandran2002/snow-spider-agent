/* ---------------------------------------------------------------------------
   1) Work out which ITEM_CATEGORY has the highest tax-to-revenue ratio for all
      GA4 purchase events that occurred on 30-Nov-2020
   2) Return – for every purchase event that contains an item of that category –
      the transaction_id, the total quantity of those items, the purchase
      revenue recorded in EVENT_VALUE_IN_USD, and the same revenue as taken
      from the ‘value’ event parameter.
---------------------------------------------------------------------------*/
WITH purchase_items AS (          -- flatten ITEMS only once
    SELECT
        i.value:"item_category"::STRING  AS item_category,
        i.value:"tax"::FLOAT             AS tax_usd,
        t."EVENT_VALUE_IN_USD"           AS purchase_revenue_usd
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130" t,
         LATERAL FLATTEN(input => t."ITEMS") i
    WHERE t."EVENT_NAME" = 'purchase'
),
top_category AS (                 -- derive the single highest tax-rate category
    SELECT item_category
    FROM (
        SELECT
            item_category,
            SUM(tax_usd) / NULLIF(SUM(purchase_revenue_usd),0) AS tax_rate
        FROM purchase_items
        GROUP BY item_category
        ORDER BY tax_rate DESC NULLS LAST
        LIMIT 1
    )
)
SELECT
    t."ECOMMERCE":transaction_id::STRING           AS transaction_id,
    SUM(i.value:"quantity"::NUMBER)                AS total_item_qty,
    t."EVENT_VALUE_IN_USD"                         AS purchase_revenue_usd,
    ep.value:"double_value"::FLOAT                 AS purchase_revenue_param_usd
FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130" t
     ,LATERAL FLATTEN(input => t."ITEMS")  i
     ,LATERAL FLATTEN(input => t."EVENT_PARAMS") ep
WHERE t."EVENT_NAME" = 'purchase'
  AND i.value:"item_category"::STRING = (SELECT item_category FROM top_category)
  AND ep.value:"key"::STRING = 'value'
GROUP BY
    transaction_id,
    purchase_revenue_usd,
    purchase_revenue_param_usd
ORDER BY transaction_id;