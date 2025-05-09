/*---------------------------------------------------------------
  1)  Find the product-category whose completed orders show the
      highest AVERAGE month-over-month % growth in DISTINCT orders
  2)  For that category, calculate the AVERAGE month-over-month
      % growth in total revenue (sum of sale_price)
----------------------------------------------------------------*/
WITH completed_items AS (       -- only “Complete” order items
    SELECT
        "order_id",
        "product_id",
        "sale_price",
        "created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "status" = 'Complete'
),

-- -------------  MONTHLY UNIQUE-ORDER COUNTS -------------------
monthly_orders AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(ci."created_at" / 1e6), 'YYYY-MM') AS "order_month",
        p."category",
        COUNT(DISTINCT ci."order_id")                               AS "num_unique_orders"
    FROM completed_items         ci
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON ci."product_id" = p."id"
    GROUP BY 1, 2
),

order_growth AS (               -- MoM % growth in unique orders
    SELECT
        "category",
        "order_month",
        "num_unique_orders",
        ROUND(
              100.0 * (
                        "num_unique_orders"
                        - LAG("num_unique_orders")
                          OVER (PARTITION BY "category" ORDER BY "order_month")
                      )
              / NULLIF(
                     LAG("num_unique_orders")
                     OVER (PARTITION BY "category" ORDER BY "order_month"), 0
                )
            , 4)                                                    AS "pct_order_growth"
    FROM monthly_orders
),

avg_order_growth AS (           -- average MoM % growth per category
    SELECT
        "category",
        AVG("pct_order_growth") AS "avg_mo_pct_order_growth"
    FROM order_growth
    WHERE "pct_order_growth" IS NOT NULL
    GROUP BY "category"
),

top_category AS (               -- the single top-performing category
    SELECT *
    FROM   avg_order_growth
    ORDER  BY "avg_mo_pct_order_growth" DESC NULLS LAST
    LIMIT 1
),

-- -------------  MONTHLY REVENUE FOR THE TOP CATEGORY ----------
monthly_revenue AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(ci."created_at" / 1e6), 'YYYY-MM') AS "order_month",
        SUM(ci."sale_price")                                        AS "monthly_revenue"
    FROM completed_items         ci
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON ci."product_id" = p."id"
    JOIN top_category tc
      ON p."category" = tc."category"
    GROUP BY 1
),

revenue_growth AS (             -- MoM % growth in revenue
    SELECT
        "order_month",
        "monthly_revenue",
        ROUND(
              100.0 * (
                        "monthly_revenue"
                        - LAG("monthly_revenue") OVER (ORDER BY "order_month")
                      )
              / NULLIF(
                     LAG("monthly_revenue") OVER (ORDER BY "order_month"), 0
                )
            , 4)                                                    AS "pct_revenue_growth"
    FROM monthly_revenue
),

avg_revenue_growth AS (         -- average MoM % revenue growth
    SELECT
        AVG("pct_revenue_growth") AS "avg_mo_pct_revenue_growth"
    FROM revenue_growth
    WHERE "pct_revenue_growth" IS NOT NULL
)

-- ------------------  FINAL RESULT ------------------------------
SELECT
    tc."category",
    tc."avg_mo_pct_order_growth",
    arg."avg_mo_pct_revenue_growth"
FROM top_category       tc
CROSS JOIN avg_revenue_growth arg;