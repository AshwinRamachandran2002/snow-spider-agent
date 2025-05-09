/*--------------------------------------------------------------
  1)  Work out the tax-rate (tax ÷ purchase_revenue_in_usd)
      for every item-category that appears in 30-Nov-2020
      purchase events and keep the highest-rate category.
  2)  For every purchase that contains at least one line-item
      in that top-tax-rate category return:
          • transaction_id
          • total item quantity in the order
          • purchase_revenue_in_usd
          • purchase_revenue         (original currency)
--------------------------------------------------------------*/
WITH purchase_rows AS (   -- one row per (event , item_category)
    SELECT
        e."EVENT_TIMESTAMP",
        it.value:"item_category"::STRING                                 AS "item_category",
        MAX(CASE WHEN ep.value:"key"::STRING = 'tax'
                 THEN COALESCE(ep.value:"value":"double_value"::FLOAT,
                              ep.value:"value":"int_value"  ::FLOAT) END) AS "tax_usd",
        MAX(CASE WHEN ep.value:"key"::STRING = 'purchase_revenue_in_usd'
                 THEN COALESCE(ep.value:"value":"double_value"::FLOAT,
                              ep.value:"value":"int_value"  ::FLOAT) END) AS "purchase_rev_usd"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130" e,
         LATERAL FLATTEN(input => e."EVENT_PARAMS") ep,
         LATERAL FLATTEN(input => e."ITEMS")         it
    WHERE e."EVENT_NAME" = 'purchase'
    GROUP BY e."EVENT_TIMESTAMP", it.value:"item_category"::STRING
),

top_category AS (         -- highest tax-rate category
    SELECT
        "item_category",
        SUM("tax_usd") / NULLIF(SUM("purchase_rev_usd"),0)  AS "tax_rate"
    FROM purchase_rows
    GROUP BY "item_category"
    ORDER BY "tax_rate" DESC NULLS LAST
    LIMIT 1
),

transaction_details AS (
    SELECT
        tc."item_category"                                              AS "item_category",
        ep_tx.value:"value":"string_value"::STRING                      AS "transaction_id",
        SUM(it.value:"quantity"::INT)                                   AS "total_item_quantity",
        MAX(CASE WHEN ep_pr.value :"key"::STRING = 'purchase_revenue_in_usd'
                 THEN ep_pr.value:"value":"double_value"::FLOAT END)    AS "purchase_revenue_usd",
        MAX(CASE WHEN ep_pr2.value:"key"::STRING = 'purchase_revenue'
                 THEN ep_pr2.value:"value":"double_value"::FLOAT END)   AS "purchase_revenue"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130" e
         , top_category tc
         , LATERAL FLATTEN(input => e."ITEMS")        it
         , LATERAL FLATTEN(input => e."EVENT_PARAMS") ep_tx
         , LATERAL FLATTEN(input => e."EVENT_PARAMS") ep_pr
         , LATERAL FLATTEN(input => e."EVENT_PARAMS") ep_pr2
    WHERE e."EVENT_NAME" = 'purchase'
      AND it.value:"item_category"::STRING = tc."item_category"  -- keep only items in top category
      AND ep_tx.value:"key"::STRING = 'transaction_id'
    GROUP BY tc."item_category", ep_tx.value:"value":"string_value"::STRING
)

SELECT *
FROM transaction_details
ORDER BY "transaction_id";