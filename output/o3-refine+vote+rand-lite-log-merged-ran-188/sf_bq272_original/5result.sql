/*  Top‑3 most‑profitable products per month
    (Jan‑2019 – Aug‑2022, Snowflake dialect)                                   */

WITH valid_order_items AS (          -- 1. keep only non‑cancelled / non‑returned sales
    SELECT
        oi."product_id",
        p."name"                            AS "product_name",
        DATE_TRUNC('month',
                   TO_TIMESTAMP(oi."created_at"/1e6))   AS "month_start",
        SUM(oi."sale_price")                AS "revenue",
        SUM(ii."cost")                      AS "cost"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"        oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"             o
           ON  oi."order_id" = o."order_id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"    ii
           ON  oi."inventory_item_id" = ii."id"
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"           p
           ON  oi."product_id" = p."id"
    WHERE o."status"           NOT IN ('Cancelled', 'Returned', 'Return')
      AND oi."status"          NOT IN ('Cancelled', 'Returned')
      AND oi."returned_at" IS NULL
      AND DATE_TRUNC('month',
                     TO_TIMESTAMP(oi."created_at"/1e6))
          BETWEEN DATE '2019-01-01' AND DATE '2022-08-01'
    GROUP BY
        oi."product_id",
        p."name",
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at"/1e6))
),

product_profit AS (                  -- 2. compute profit = revenue – cost
    SELECT
        "product_id",
        "product_name",
        "month_start",
        ("revenue" - "cost")          AS "profit"
    FROM   valid_order_items
),

ranked AS (                          -- 3. rank products by profit within each month
    SELECT
        "month_start",
        "product_name",
        "profit",
        ROW_NUMBER() OVER (PARTITION BY "month_start"
                           ORDER BY "profit" DESC)  AS rn
    FROM   product_profit
)

-- 4. return the top‑3 products per month
SELECT
    "month_start"          AS "month_start_date",
    "product_name",
    ROUND("profit", 4)     AS "profit"
FROM   ranked
WHERE  rn <= 3
ORDER  BY
    "month_start",          -- chronological order
    "profit" DESC;          -- within a month, highest profit first