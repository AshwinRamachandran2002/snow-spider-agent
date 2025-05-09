WITH purchase_events AS (
    SELECT
        t."EVENT_TIMESTAMP",
        t."ITEMS",
        MAX(CASE WHEN f.value:"key"::STRING = 'transaction_id' THEN f.value:"value":"string_value"::STRING END) AS "transaction_id",
        MAX(CASE WHEN f.value:"key"::STRING = 'tax' THEN f.value:"value":"double_value"::FLOAT END) AS "tax_value_in_usd",
        MAX(CASE WHEN f.value:"key"::STRING = 'value' THEN f.value:"value":"double_value"::FLOAT END) AS "purchase_revenue_in_usd"
    FROM
        "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201130" t,
        LATERAL FLATTEN(input => t."EVENT_PARAMS") f
    WHERE
        t."EVENT_NAME" = 'purchase'
        AND t."EVENT_DATE" = '20201130'
    GROUP BY
        t."EVENT_TIMESTAMP", t."ITEMS"
    HAVING
        MAX(CASE WHEN f.value:"key"::STRING = 'transaction_id' THEN 1 ELSE 0 END) = 1
        AND MAX(CASE WHEN f.value:"key"::STRING = 'tax' THEN 1 ELSE 0 END) = 1
        AND MAX(CASE WHEN f.value:"key"::STRING = 'value' THEN 1 ELSE 0 END) = 1
),
event_details AS (
    SELECT
        pe."transaction_id",
        pe."tax_value_in_usd",
        pe."purchase_revenue_in_usd",
        ROUND((pe."tax_value_in_usd" / pe."purchase_revenue_in_usd"), 4) AS "tax_rate",
        pe."ITEMS"
    FROM
        purchase_events pe
    WHERE
        pe."tax_value_in_usd" IS NOT NULL
        AND pe."purchase_revenue_in_usd" IS NOT NULL
),
item_categories AS (
    SELECT
        ed."transaction_id",
        ed."purchase_revenue_in_usd",
        ed."tax_rate",
        item.value:"item_category"::STRING AS "item_category",
        item.value:"quantity"::NUMBER AS "item_quantity"
    FROM
        event_details ed,
        LATERAL FLATTEN(input => ed."ITEMS") item
),
max_tax_rate_category AS (
    SELECT
        "item_category",
        MAX("tax_rate") AS "max_tax_rate"
    FROM
        item_categories
    GROUP BY
        "item_category"
    ORDER BY
        "max_tax_rate" DESC NULLS LAST
    LIMIT 1
),
final_data AS (
    SELECT
        ic."transaction_id",
        SUM(ic."item_quantity") AS "total_item_quantity",
        ic."purchase_revenue_in_usd",
        ic."purchase_revenue_in_usd" AS "purchase_revenue"
    FROM
        item_categories ic
        JOIN max_tax_rate_category mtc ON ic."item_category" = mtc."item_category"
    GROUP BY
        ic."transaction_id", ic."purchase_revenue_in_usd"
)
SELECT
    "transaction_id",
    "total_item_quantity",
    ROUND("purchase_revenue_in_usd", 4) AS "purchase_revenue_in_usd",
    ROUND("purchase_revenue", 4) AS "purchase_revenue"
FROM
    final_data
ORDER BY
    "transaction_id";