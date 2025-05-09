WITH order_items_clean AS (   -- 1. keep only non‑cancelled / non‑returned sales in the period
    SELECT
        oi."order_id",
        oi."product_id",
        oi."sale_price",
        ii."cost",
        oi."created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o
           ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
           ON oi."inventory_item_id" = ii."id"
    WHERE  COALESCE(o."status",'') NOT ILIKE 'Cancelled'
      AND  COALESCE(oi."status",'') NOT ILIKE 'Cancelled'
      AND  o."returned_at" IS NULL
      AND  oi."returned_at" IS NULL
      AND  DATE_TRUNC(
              'month',
              TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
           )
           BETWEEN '2019-01-01' AND '2022-08-31'
),
monthly_profit AS (          -- 2. profit per product per month
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ("created_at" / 1000000)
        )                         AS "month",
        "product_id",
        SUM("sale_price") - SUM("cost")  AS "profit"
    FROM order_items_clean
    GROUP BY "month", "product_id"
),
ranked_profit AS (           -- 3. rank products by profit within each month
    SELECT
        mp."month",
        p."name"        AS "product_name",
        mp."profit",
        ROW_NUMBER() OVER (
            PARTITION BY mp."month"
            ORDER BY mp."profit" DESC NULLS LAST, p."name"
        ) AS rn
    FROM monthly_profit mp
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON mp."product_id" = p."id"
)
-- 4. top‑3 most profitable products per month (Jan‑2019 – Aug‑2022)
SELECT
    "month",
    "product_name",
    "profit"
FROM ranked_profit
WHERE rn <= 3
ORDER BY "month", "profit" DESC, "product_name";