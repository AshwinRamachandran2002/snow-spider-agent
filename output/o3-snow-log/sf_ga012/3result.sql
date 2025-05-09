/*-------------------------------------------------------------------
   30-Nov-2020  –  highest-tax-rate item-category
   and every purchase that belongs to that category
-------------------------------------------------------------------*/
WITH purchases AS (          /* ── event-level revenue / tax ── */
    SELECT
        e."EVENT_TIMESTAMP",
        MAX(e."EVENT_VALUE_IN_USD")                                              AS revenue_usd_col,
        MAX(CASE WHEN ep.value:"key" = 'value'
                 THEN COALESCE(ep.value:"double_value",
                              ep.value:"int_value")::FLOAT END)                 AS revenue_param,
        MAX(CASE WHEN ep.value:"key" = 'tax'
                 THEN COALESCE(ep.value:"double_value",
                              ep.value:"int_value")::FLOAT END)                 AS tax_param,
        MAX(CASE WHEN ep.value:"key" = 'transaction_id'
                 THEN ep.value:"string_value"::STRING END)                      AS transaction_id
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"  e,
         LATERAL FLATTEN (INPUT => e."EVENT_PARAMS")               ep
    WHERE e."EVENT_NAME" = 'purchase'
    GROUP BY e."EVENT_TIMESTAMP"
),
items AS (                /* ── unnest ITEMS ── */
    SELECT
        e."EVENT_TIMESTAMP",
        COALESCE(it.value:"item_category"::STRING,'(not set)')      AS item_category,
        COALESCE(it.value:"quantity"::NUMBER,1)                     AS qty
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"  e,
         LATERAL FLATTEN (INPUT => e."ITEMS")                  it
    WHERE e."EVENT_NAME" = 'purchase'
),
event_cat AS (            /* ── join purchases + items ── */
    SELECT
        p.transaction_id,
        i.item_category,
        SUM(i.qty)                                           AS total_qty,
        COALESCE(p.revenue_usd_col, p.revenue_param)         AS revenue_usd,
        COALESCE(p.tax_param,0)                              AS tax_usd
    FROM purchases p
    JOIN items i
      ON p."EVENT_TIMESTAMP" = i."EVENT_TIMESTAMP"
    GROUP BY p.transaction_id,
             i.item_category,
             COALESCE(p.revenue_usd_col, p.revenue_param),
             COALESCE(p.tax_param,0)
),
top_cat AS (              /* ── category with highest avg tax-rate ── */
    SELECT item_category
    FROM (
        SELECT
            item_category,
            AVG(tax_usd / NULLIF(revenue_usd,0)) AS avg_tax_rate
        FROM event_cat
        WHERE revenue_usd IS NOT NULL
          AND revenue_usd <> 0
        GROUP BY item_category
        ORDER BY avg_tax_rate DESC NULLS LAST
        LIMIT 1
    )
)
SELECT
    ec.transaction_id,
    ec.total_qty            AS total_item_quantity,
    ec.revenue_usd          AS purchase_revenue_usd,
    ec.revenue_usd          AS purchase_revenue           -- same figure, different label
FROM event_cat  ec
JOIN top_cat    tc
  ON ec.item_category = tc.item_category
ORDER BY ec.transaction_id;