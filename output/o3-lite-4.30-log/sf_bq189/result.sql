WITH "monthly" AS (   -- KPI per category per month, completed orders only
    SELECT
        TO_CHAR(TO_TIMESTAMP("oi"."created_at" / 1000000), 'YYYY-MM') AS "yyyymm",
        "p"."category",
        COUNT(DISTINCT "oi"."order_id")                               AS "orders_cnt",
        SUM("oi"."sale_price")                                        AS "revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"    AS "p"
          ON "oi"."product_id" = "p"."id"
    WHERE "oi"."status" = 'Complete'
    GROUP BY 1, 2
),
/* Month‑over‑month % growth in unique orders */
"orders_growth" AS (
    SELECT
        "category",
        ( "orders_cnt"
          - LAG("orders_cnt") OVER (PARTITION BY "category" ORDER BY "yyyymm") )
        / NULLIF( LAG("orders_cnt") OVER (PARTITION BY "category" ORDER BY "yyyymm"), 0 )
        AS "order_growth_pct"
    FROM "monthly"
),
/* Average MoM order‑growth for every category */
"avg_orders_growth" AS (
    SELECT
        "category",
        AVG("order_growth_pct") AS "avg_order_growth_pct"
    FROM "orders_growth"
    WHERE "order_growth_pct" IS NOT NULL
    GROUP BY "category"
),
/* Category with the highest average MoM order‑growth */
"best_cat" AS (
    SELECT "category"
    FROM "avg_orders_growth"
    ORDER BY "avg_order_growth_pct" DESC NULLS LAST
    LIMIT 1
),
/* MoM % revenue growth for the best category */
"revenue_growth" AS (
    SELECT
        m."yyyymm",
        m."category",
        ( m."revenue" - LAG(m."revenue") OVER (ORDER BY m."yyyymm") )
        / NULLIF( LAG(m."revenue") OVER (ORDER BY m."yyyymm"), 0 ) AS "revenue_growth_pct"
    FROM "monthly" m
    JOIN "best_cat" bc
          ON m."category" = bc."category"
),
/* Average MoM revenue‑growth for that category */
"avg_revenue_growth" AS (
    SELECT
        (SELECT "category" FROM "best_cat") AS "category",
        AVG("revenue_growth_pct")           AS "avg_revenue_growth_pct"
    FROM "revenue_growth"
    WHERE "revenue_growth_pct" IS NOT NULL
)
SELECT
    a."category",
    ROUND(a."avg_order_growth_pct"  * 100, 4) AS "avg_monthly_order_growth_pct",
    ROUND(r."avg_revenue_growth_pct" * 100, 4) AS "avg_monthly_revenue_growth_pct"
FROM "avg_orders_growth" a
JOIN "best_cat"           b ON a."category" = b."category"
JOIN "avg_revenue_growth" r ON a."category" = r."category";