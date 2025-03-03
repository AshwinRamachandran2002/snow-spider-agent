WITH event_tax_rates AS (
    SELECT
        t."EVENT_TIMESTAMP",
        MAX(CASE WHEN ep.value:"key"::string = 'tax' THEN ep.value:"value":"double_value"::float END) AS tax_value_usd,
        MAX(CASE WHEN ep.value:"key"::string = 'value' THEN ep.value:"value":"double_value"::float END) AS purchase_revenue_usd
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201130" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") ep
    WHERE t."EVENT_DATE" = '20201130' AND t."EVENT_NAME" = 'purchase'
    GROUP BY t."EVENT_TIMESTAMP"
),
event_tax_rates_calculated AS (
    SELECT
        "EVENT_TIMESTAMP",
        (tax_value_usd / purchase_revenue_usd) AS tax_rate
    FROM event_tax_rates
    WHERE tax_value_usd IS NOT NULL AND purchase_revenue_usd IS NOT NULL
),
event_items AS (
    SELECT
        t."EVENT_TIMESTAMP",
        item.value:"item_category"::string AS item_category
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201130" t,
         LATERAL FLATTEN(input => t."ITEMS") item
    WHERE t."EVENT_DATE" = '20201130' AND t."EVENT_NAME" = 'purchase'
),
event_item_tax_rate AS (
    SELECT
        eitr."EVENT_TIMESTAMP",
        ei.item_category,
        eitr.tax_rate
    FROM event_tax_rates_calculated eitr
    JOIN event_items ei ON eitr."EVENT_TIMESTAMP" = ei."EVENT_TIMESTAMP"
),
item_category_tax_rates AS (
    SELECT
        item_category,
        AVG(tax_rate) AS avg_tax_rate
    FROM event_item_tax_rate
    GROUP BY item_category
),
top_tax_category AS (
    SELECT
        item_category
    FROM item_category_tax_rates
    ORDER BY avg_tax_rate DESC NULLS LAST
    LIMIT 1
),
events_with_top_category AS (
    SELECT DISTINCT
        eit."EVENT_TIMESTAMP"
    FROM event_item_tax_rate eit
    JOIN top_tax_category ttc ON eit.item_category = ttc.item_category
),
transaction_details AS (
    SELECT
        t."EVENT_TIMESTAMP",
        MAX(CASE WHEN ep.value:"key"::string = 'transaction_id' THEN ep.value:"value":"string_value"::string END) AS transaction_id,
        MAX(CASE WHEN ep.value:"key"::string = 'value' THEN ep.value:"value":"double_value"::float END) AS purchase_revenue_in_usd,
        MAX(CASE WHEN ep.value:"key"::string = 'value' THEN ep.value:"value":"double_value"::float END) AS purchase_revenue
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201130" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") ep
    WHERE t."EVENT_DATE" = '20201130' AND t."EVENT_NAME" = 'purchase'
    GROUP BY t."EVENT_TIMESTAMP"
),
item_quantities AS (
    SELECT
        t."EVENT_TIMESTAMP",
        SUM(item.value:"quantity"::number) AS total_item_quantity
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201130" t,
         LATERAL FLATTEN(input => t."ITEMS") item
    WHERE t."EVENT_DATE" = '20201130' AND t."EVENT_NAME" = 'purchase'
    GROUP BY t."EVENT_TIMESTAMP"
)
SELECT
    td.transaction_id,
    iq.total_item_quantity,
    td.purchase_revenue_in_usd,
    td.purchase_revenue
FROM transaction_details td
JOIN item_quantities iq ON td."EVENT_TIMESTAMP" = iq."EVENT_TIMESTAMP"
JOIN events_with_top_category ewtc ON td."EVENT_TIMESTAMP" = ewtc."EVENT_TIMESTAMP";