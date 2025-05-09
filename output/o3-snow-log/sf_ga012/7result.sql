/*--------------------------------------------------------------
  1) Build an event-level view of every “purchase” that occurred
     on 2020-11-30 (one row per event, grouped by timestamp +
     EVENT_VALUE_IN_USD).  Pull out the tax amount, transaction
     id, total item quantity, revenues and the item_category
     attached to the event.

  2) From that set, find the single item_category whose overall
     tax-rate  ( Σ tax_usd  /  Σ purchase_revenue_usd )  is
     highest.

  3) Return every purchase event that belongs to that top
     tax-rate category, listing the requested fields.
--------------------------------------------------------------*/
WITH purchase_events AS (      -- step-1
    SELECT  t."EVENT_TIMESTAMP",
            MIN(CASE WHEN f.value:"key"::STRING = 'transaction_id'
                     THEN f.value:"value":"string_value"::STRING END)        AS "transaction_id",
            SUM(i.value:"quantity"::NUMBER)                                  AS "total_item_qty",
            MIN(CASE WHEN f.value:"key"::STRING = 'tax'
                     THEN f.value:"value":"double_value"::FLOAT END)         AS "tax_usd",
            t."EVENT_VALUE_IN_USD"                                           AS "purchase_revenue_usd",
            MIN(CASE WHEN f.value:"key"::STRING = 'purchase_revenue'
                     THEN f.value:"value":"double_value"::FLOAT END)         AS "purchase_revenue",
            MAX(i.value:"item_category"::STRING)                             AS "item_category"
    FROM    GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"  t,
            LATERAL FLATTEN(input => t."EVENT_PARAMS")            f,
            LATERAL FLATTEN(input => t."ITEMS")                   i
    WHERE   t."EVENT_NAME" = 'purchase'
    GROUP BY t."EVENT_TIMESTAMP", t."EVENT_VALUE_IN_USD"
),
ranked_category AS (           -- step-2
    SELECT  "item_category",
            SUM("tax_usd") / NULLIF(SUM("purchase_revenue_usd"),0)  AS "tax_rate"
    FROM    purchase_events
    GROUP BY "item_category"
    HAVING  SUM("purchase_revenue_usd") <> 0            -- exclude zero revenue
           AND SUM("tax_usd") IS NOT NULL               -- exclude missing tax
    ORDER BY "tax_rate" DESC NULLS LAST
    LIMIT 1
)
-- step-3 : final answer
SELECT  p."transaction_id",
        p."total_item_qty",
        p."purchase_revenue_usd",
        p."purchase_revenue"
FROM    purchase_events  p
JOIN    ranked_category  r
      ON p."item_category" = r."item_category"
ORDER BY p."transaction_id";