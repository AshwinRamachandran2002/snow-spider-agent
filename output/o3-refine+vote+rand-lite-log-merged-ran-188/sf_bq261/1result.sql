WITH per_item AS (   -- one row per order item with its month, unit‑cost and profit
    SELECT
        DATE_TRUNC('MONTH',
                   TO_TIMESTAMP_NTZ("created_at" / 1000000)   -- micro‑seconds → timestamp
                  )::DATE                                    AS "MONTH_START",
        oi."product_id"                                      AS "PRODUCT_ID",
        p."name"                                             AS "PRODUCT_NAME",
        p."cost"                                             AS "UNIT_COST",
        oi."sale_price"                                      AS "SALE_PRICE",
        (oi."sale_price" - p."cost")                         AS "PROFIT"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE TO_TIMESTAMP_NTZ(oi."created_at" / 1000000) < '2024-01-01'   -- exclude Jan‑24 onward
), aggregated AS (      -- total cost & profit per product per month
    SELECT
        "MONTH_START",
        "PRODUCT_ID",
        "PRODUCT_NAME",
        SUM("UNIT_COST")                AS "TOTAL_COST",
        SUM("PROFIT")                   AS "TOTAL_PROFIT"
    FROM per_item
    GROUP BY "MONTH_START", "PRODUCT_ID", "PRODUCT_NAME"
), ranked AS (          -- pick product with highest profit within each month
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "MONTH_START"
                           ORDER BY "TOTAL_PROFIT" DESC)     AS rn
    FROM aggregated
)
SELECT
    "MONTH_START"   AS "MONTH",
    "PRODUCT_ID",
    "PRODUCT_NAME",
    "TOTAL_COST",
    "TOTAL_PROFIT"
FROM ranked
WHERE rn = 1                       -- highest‑profit product for the month
ORDER BY "MONTH";                  -- chronological order