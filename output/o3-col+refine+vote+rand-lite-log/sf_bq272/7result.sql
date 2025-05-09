/*  Top-3 most profitable products per month (Jan-2019 ‑ Aug-2022)
    Profit = Σ(sale_price) − Σ(cost) for all qualifying order items          */

WITH monthly_profit AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("oi"."created_at" / 1000000)
        )                                                       AS "order_month",
        "oi"."product_id",
        SUM("oi"."sale_price" - "ii"."cost")                    AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           AS "o"
         ON "oi"."order_id" = "o"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  AS "ii"
         ON "oi"."inventory_item_id" = "ii"."id"
    WHERE
          -- Exclude cancelled / returned orders
          UPPER("o"."status")     NOT IN ('CANCELLED', 'RETURNED')
      AND UPPER("oi"."status")    NOT IN ('CANCELLED', 'RETURNED')
      AND "oi"."returned_at" IS NULL
          -- Restrict to required period
      AND DATE_TRUNC(
              'month',
              TO_TIMESTAMP("oi"."created_at" / 1000000)
          ) BETWEEN '2019-01-01' AND '2022-08-01'
    GROUP BY
        "order_month",
        "oi"."product_id"
),

ranked_products AS (
    SELECT
        mp.*,
        RANK() OVER (
            PARTITION BY "order_month"
            ORDER BY "profit" DESC NULLS LAST
        )                                                       AS "profit_rank"
    FROM monthly_profit mp
)

SELECT
    "rp"."order_month",
    "p"."name"                                  AS "product_name",
    ROUND("rp"."profit", 4)                     AS "profit",
    "rp"."profit_rank"
FROM ranked_products          AS "rp"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" AS "p"
  ON "rp"."product_id" = "p"."id"
WHERE "rp"."profit_rank" <= 3
ORDER BY
    "rp"."order_month",
    "rp"."profit_rank";