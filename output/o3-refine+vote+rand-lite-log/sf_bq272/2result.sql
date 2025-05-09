WITH valid_order_items AS (          -- keep only non‑cancelled & non‑returned items
    SELECT
        "product_id",
        "inventory_item_id",
        "sale_price",
        "created_at",
        TO_TIMESTAMP("created_at"/1000000)      AS created_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "status" <> 'Cancelled'
      AND "returned_at" IS NULL
),
order_items_with_cost AS (           -- attach the unit cost and month of sale
    SELECT
        voi."product_id",
        voi."sale_price",
        ii."cost",
        DATE_TRUNC('month', voi.created_ts)     AS month_start
    FROM valid_order_items   voi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii
          ON voi."inventory_item_id" = ii."id"
),
profit_per_product_month AS (        -- profit per product per month
    SELECT
        month_start,
        "product_id",
        SUM("sale_price")                     AS total_sales,
        SUM("cost")                           AS total_cost,
        SUM("sale_price") - SUM("cost")       AS profit
    FROM order_items_with_cost
    WHERE month_start >= '2019-01-01'
      AND month_start <  '2022-09-01'         -- up to Aug‑2022 inclusive
    GROUP BY month_start, "product_id"
),
ranked_products AS (                 -- pick the three most profitable each month
    SELECT
        month_start,
        "product_id",
        profit,
        ROW_NUMBER() OVER (PARTITION BY month_start
                           ORDER BY profit DESC, "product_id") AS rn
    FROM profit_per_product_month
)
SELECT
    TO_VARCHAR(month_start, 'YYYY-MM')         AS "month",
    p."name"                                   AS "product_name",
    ROUND(rp.profit, 4)                        AS "profit"
FROM ranked_products  rp
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON rp."product_id" = p."id"
WHERE rn <= 3
ORDER BY month_start, profit DESC, "product_name";