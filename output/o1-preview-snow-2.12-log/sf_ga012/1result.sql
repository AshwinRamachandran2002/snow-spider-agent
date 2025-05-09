WITH purchase_events AS (
    SELECT *
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201130"
    WHERE "EVENT_NAME" = 'purchase' AND "EVENT_DATE" = '20201130'
),
event_params AS (
    SELECT
        pe."EVENT_TIMESTAMP",
        ep.value:"key"::STRING AS param_key,
        ep.value:"value" AS param_value
    FROM
        purchase_events pe,
        LATERAL FLATTEN(input => pe."EVENT_PARAMS") ep
),
event_values AS (
    SELECT
        "EVENT_TIMESTAMP",
        MAX(CASE WHEN param_key = 'tax' THEN param_value:"double_value"::FLOAT END) AS tax_value,
        MAX(CASE WHEN param_key = 'value' THEN param_value:"double_value"::FLOAT END) AS purchase_revenue,
        MAX(CASE WHEN param_key = 'transaction_id' THEN param_value:"string_value"::STRING END) AS transaction_id
    FROM event_params
    GROUP BY "EVENT_TIMESTAMP"
),
event_items AS (
    SELECT
        pe."EVENT_TIMESTAMP",
        i.value:"item_category"::STRING AS item_category,
        i.value:"item_revenue_in_usd"::FLOAT AS item_revenue_in_usd,
        i.value:"quantity"::FLOAT AS quantity
    FROM
        purchase_events pe,
        LATERAL FLATTEN(input => pe."ITEMS") i
),
total_item_revenue AS (
    SELECT
        "EVENT_TIMESTAMP",
        SUM(item_revenue_in_usd) AS total_item_revenue
    FROM event_items
    GROUP BY "EVENT_TIMESTAMP"
),
allocated_item_values AS (
    SELECT
        ei."EVENT_TIMESTAMP",
        ei.item_category,
        ei.quantity,
        (ei.item_revenue_in_usd / tir.total_item_revenue) * ev.tax_value AS allocated_tax_value,
        (ei.item_revenue_in_usd / tir.total_item_revenue) * ev.purchase_revenue AS allocated_purchase_revenue
    FROM
        event_items ei
    JOIN total_item_revenue tir ON ei."EVENT_TIMESTAMP" = tir."EVENT_TIMESTAMP"
    JOIN event_values ev ON ei."EVENT_TIMESTAMP" = ev."EVENT_TIMESTAMP"
    WHERE ev.tax_value IS NOT NULL AND ev.purchase_revenue IS NOT NULL
),
item_category_tax_rates AS (
    SELECT
        item_category,
        SUM(allocated_tax_value) AS total_allocated_tax_value,
        SUM(allocated_purchase_revenue) AS total_allocated_purchase_revenue,
        (SUM(allocated_tax_value) / NULLIF(SUM(allocated_purchase_revenue), 0)) AS tax_rate
    FROM allocated_item_values
    GROUP BY item_category
    ORDER BY tax_rate DESC NULLS LAST
    LIMIT 1
),
transactions_with_top_category AS (
    SELECT DISTINCT
        ev.transaction_id,
        ev."EVENT_TIMESTAMP",
        ev.purchase_revenue
    FROM event_values ev
    JOIN event_items ei ON ev."EVENT_TIMESTAMP" = ei."EVENT_TIMESTAMP"
    JOIN item_category_tax_rates ttc ON ei.item_category = ttc.item_category
)
SELECT
    twtc.transaction_id,
    SUM(ei.quantity) AS total_item_quantity,
    ROUND(twtc.purchase_revenue, 4) AS purchase_revenue_in_usd,
    ROUND(twtc.purchase_revenue, 4) AS purchase_revenue
FROM
    transactions_with_top_category twtc
JOIN event_items ei ON twtc."EVENT_TIMESTAMP" = ei."EVENT_TIMESTAMP"
JOIN item_category_tax_rates ttc ON ei.item_category = ttc.item_category
GROUP BY
    twtc.transaction_id, twtc.purchase_revenue
ORDER BY twtc.transaction_id;