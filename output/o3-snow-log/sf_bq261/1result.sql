WITH item_level AS (
    /* 1.  Bring every order item to the row level,
           attach the product cost,
           and turn the micro-second epoch into a real timestamp month. */
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("oi"."created_at" / 1000000)
        )                                      AS "order_month",
        "oi"."product_id"                      AS "product_id",
        "p"."name"                             AS "product_name",
        /* cost per item (from PRODUCTS)                            */
        "p"."cost"                             AS "cost",
        /* profit per item                                           */
        ("oi"."sale_price" - "p"."cost")       AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      AS "p"
      ON "oi"."product_id" = "p"."id"
    WHERE DATE_TRUNC(
              'month',
              TO_TIMESTAMP("oi"."created_at" / 1000000)
          ) < DATE '2024-01-01'          --  only months prior to Jan-2024
),

product_month_totals AS (
    /* 2.  Aggregate to (month, product) level                      */
    SELECT
        "order_month",
        "product_id",
        "product_name",
        SUM("cost")   AS "total_cost",
        SUM("profit") AS "total_profit"
    FROM item_level
    GROUP BY
        "order_month",
        "product_id",
        "product_name"
),

ranked AS (
    /* 3.  Within each month, rank products by total profit          */
    SELECT
        *,
        RANK() OVER (
            PARTITION BY "order_month"
            ORDER BY "total_profit" DESC
        ) AS "profit_rank"
    FROM product_month_totals
)

SELECT
    TO_CHAR("order_month", 'YYYY-MM')      AS "month",
    "product_id",
    "product_name",
    ROUND("total_cost",   4)               AS "total_cost",
    ROUND("total_profit", 4)               AS "total_profit"
FROM ranked
WHERE "profit_rank" = 1                    -- top product of the month
ORDER BY "order_month";