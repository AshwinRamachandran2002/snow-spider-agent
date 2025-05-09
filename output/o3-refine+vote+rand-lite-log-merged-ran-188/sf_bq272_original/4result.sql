/*  Top‑3 most profitable products per month (Jan‑2019 ‑ Aug‑2022)                */
/*  Profit = Σ(sale_price) – Σ(cost of the inventory items sold)                 */
/*  Excludes any order items (and their parent orders) that were cancelled/returned */

WITH order_items_filtered AS (       -- keep only truly completed sales
    SELECT
        oi."product_id",
        oi."sale_price",
        ii."cost",
        oi."created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"        AS oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"    AS ii
          ON oi."inventory_item_id" = ii."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"             AS o
          ON oi."order_id" = o."order_id"
    WHERE   oi."status"      NOT IN ('Cancelled','Returned')
        AND o."status"       NOT IN ('Cancelled','Returned')
        AND oi."returned_at" IS NULL
        -- restrict to the required date window
        AND TO_TIMESTAMP_NTZ(oi."created_at"/1000000) >= '2019-01-01'
        AND TO_TIMESTAMP_NTZ(oi."created_at"/1000000) <  '2022-09-01'
),

monthly_profit AS (                 -- profit per product per month
    SELECT
        TO_CHAR( TO_TIMESTAMP_NTZ("created_at"/1000000), 'YYYY‑MM')  AS "year_month",
        "product_id",
        SUM("sale_price") - SUM("cost")                              AS profit
    FROM order_items_filtered
    GROUP BY "year_month", "product_id"
),

ranked_profit AS (                  -- rank products by profit within each month
    SELECT
        mp."year_month",
        p."name"                                   AS product_name,
        mp.profit,
        ROW_NUMBER() OVER (PARTITION BY mp."year_month"
                           ORDER BY mp.profit DESC) AS rn
    FROM monthly_profit mp
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON mp."product_id" = p."id"
)

SELECT
    "year_month",
    product_name,
    ROUND(profit, 4) AS profit
FROM ranked_profit
WHERE rn <= 3
ORDER BY "year_month", rn;