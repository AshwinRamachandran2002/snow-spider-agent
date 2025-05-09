/*------------------------------------------------------------
  1) Identify the item_category that carries the highest tax-rate
     (= SUM(tax_usd) / SUM(revenue_usd)) on 30-Nov-2020.
  2) For every purchase event that contains at least one item
     in that top-tax-rate category, return
          • transaction_id
          • total_item_quantity (only items in that category)
          • purchase_revenue_usd   (sum item_revenue_in_usd)
          • purchase_revenue       (sum item_revenue – original currency)
------------------------------------------------------------*/
WITH top_cat AS (   -- highest-tax-rate category
    SELECT
        i.value:"item_category"::STRING AS item_category
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"  t,
         LATERAL FLATTEN(input => t."ITEMS") i
    WHERE t."EVENT_NAME" = 'purchase'
    GROUP BY 1
    HAVING SUM(i.value:"item_revenue_in_usd"::FLOAT) > 0
    ORDER BY SUM(i.value:"item_tax_in_usd"::FLOAT)
            / NULLIF(SUM(i.value:"item_revenue_in_usd"::FLOAT),0) DESC NULLS LAST
    LIMIT 1
)

SELECT
    /* transaction id written into EVENT_PARAMS */
    MAX(CASE WHEN ep.value:"key"::STRING = 'transaction_id'
             THEN ep.value:"value":"string_value"::STRING END)  AS "transaction_id",
    SUM(i.value:"item_quantity"::NUMBER)                       AS "total_item_quantity",
    SUM(i.value:"item_revenue_in_usd"::FLOAT)                  AS "purchase_revenue_usd",
    SUM(i.value:"item_revenue"::FLOAT)                         AS "purchase_revenue"
FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"  t,
     LATERAL FLATTEN(input => t."ITEMS")        i,
     LATERAL FLATTEN(input => t."EVENT_PARAMS") ep,
     top_cat
WHERE t."EVENT_NAME" = 'purchase'
  AND i.value:"item_category"::STRING = top_cat.item_category   -- filter to top category
GROUP BY t."EVENT_TIMESTAMP"                                    -- one row per purchase
ORDER BY "transaction_id";