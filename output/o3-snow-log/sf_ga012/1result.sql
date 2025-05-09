/*---------------------------------------------------------------------------
  1) Find the item_category whose purchases on 30-Nov-2020 carry the
     highest overall tax-to-revenue ratio.
  2) Return, for every purchase event that contains that category:
        • transaction_id
        • total quantity of that category bought in the event
        • purchase_revenue_usd  (value parameter)
        • purchase_revenue      (purchase_revenue parameter, if present)
---------------------------------------------------------------------------*/
WITH event_params AS (          -- pull tax & both revenue fields
    SELECT
        t."EVENT_BUNDLE_SEQUENCE_ID",
        MAX(CASE WHEN f.value:"key"::STRING = 'tax'
                 THEN COALESCE(f.value:"value":"double_value",
                               f.value:"value":"int_value") END)           AS tax_usd,
        MAX(CASE WHEN f.value:"key"::STRING = 'value'
                 THEN COALESCE(f.value:"value":"double_value",
                               f.value:"value":"int_value") END)           AS purchase_revenue_usd,
        MAX(CASE WHEN f.value:"key"::STRING = 'purchase_revenue'
                 THEN COALESCE(f.value:"value":"double_value",
                               f.value:"value":"int_value") END)           AS purchase_revenue
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"  t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS")              f
    WHERE t."EVENT_NAME" = 'purchase'
    GROUP BY t."EVENT_BUNDLE_SEQUENCE_ID"
),
item_quantities AS (             -- one row per (event, category)
    SELECT
        t."EVENT_BUNDLE_SEQUENCE_ID",
        i.value:"item_category"::STRING                  AS item_category,
        SUM(COALESCE(i.value:"quantity"::NUMBER,1))     AS total_item_qty
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"  t,
         LATERAL FLATTEN(input => t."ITEMS")             i
    WHERE t."EVENT_NAME" = 'purchase'
    GROUP BY t."EVENT_BUNDLE_SEQUENCE_ID",
             i.value:"item_category"::STRING
),
category_rates AS (              -- compute tax / revenue per category
    SELECT
        iq.item_category,
        SUM(ep.tax_usd)          AS total_tax_usd,
        SUM(ep.purchase_revenue_usd) AS total_revenue_usd,
        SUM(ep.tax_usd) / NULLIF(SUM(ep.purchase_revenue_usd),0) AS tax_rate
    FROM item_quantities iq
    JOIN event_params   ep
          ON ep."EVENT_BUNDLE_SEQUENCE_ID" = iq."EVENT_BUNDLE_SEQUENCE_ID"
    GROUP BY iq.item_category
),
top_category AS (                -- keep the single highest-rate category
    SELECT item_category
    FROM   category_rates
    ORDER  BY tax_rate DESC NULLS LAST
    LIMIT  1
)
SELECT
    t."ECOMMERCE":"transaction_id"::STRING          AS transaction_id,
    iq.total_item_qty,
    ep.purchase_revenue_usd,
    ep.purchase_revenue
FROM item_quantities        iq
JOIN event_params           ep
      ON ep."EVENT_BUNDLE_SEQUENCE_ID" = iq."EVENT_BUNDLE_SEQUENCE_ID"
JOIN GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"  t
      ON t."EVENT_BUNDLE_SEQUENCE_ID" = iq."EVENT_BUNDLE_SEQUENCE_ID"
     AND t."EVENT_NAME" = 'purchase'
WHERE iq.item_category = (SELECT item_category FROM top_category)
ORDER BY ep.purchase_revenue_usd DESC NULLS LAST;