/* ----------------------------------------------------------
   1)  Pull only COMPLETED order‑items and attach their product
       category and month of purchase
   ---------------------------------------------------------- */
WITH completed AS (       
    SELECT
        p."category"                                                    AS "category",
        DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000))     AS "order_month",
        oi."order_id"                                                   AS "order_id",
        oi."sale_price"                                                 AS "sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
           ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
           ON oi."product_id" = p."id"
    WHERE o."status"  = 'Complete'
      AND oi."status" = 'Complete'
),

/* ----------------------------------------------------------
   2)  Monthly facts – number of DISTINCT orders and revenue
   ---------------------------------------------------------- */
monthly_facts AS (
    SELECT
        "category",
        "order_month",
        COUNT(DISTINCT "order_id")        AS "unique_orders",
        SUM("sale_price")                 AS "revenue"
    FROM completed
    GROUP BY "category", "order_month"
),

/* ----------------------------------------------------------
   3)  Month‑over‑month % growth in UNIQUE ORDERS
   ---------------------------------------------------------- */
order_growth AS (
    SELECT
        "category",
        "order_month",
        "unique_orders",
        LAG("unique_orders") OVER (PARTITION BY "category"
                                   ORDER BY "order_month")   AS "prev_orders",
        CASE
            WHEN LAG("unique_orders") OVER (PARTITION BY "category"
                                            ORDER BY "order_month") IS NULL
              OR LAG("unique_orders") OVER (PARTITION BY "category"
                                            ORDER BY "order_month") = 0
            THEN NULL
            ELSE ( "unique_orders"
                   - LAG("unique_orders") OVER (PARTITION BY "category"
                                                ORDER BY "order_month") )
                 / LAG("unique_orders") OVER (PARTITION BY "category"
                                              ORDER BY "order_month") * 100
        END                                                   AS "pct_order_growth"
    FROM monthly_facts
),

/* ----------------------------------------------------------
   4)  Average monthly order growth per category
   ---------------------------------------------------------- */
avg_order_growth AS (
    SELECT
        "category",
        AVG("pct_order_growth")        AS "avg_monthly_order_growth"
    FROM order_growth
    GROUP BY "category"
),

/* ----------------------------------------------------------
   5)  Pick the category with the HIGHEST avg order growth
   ---------------------------------------------------------- */
top_category AS (
    SELECT *
    FROM   avg_order_growth
    QUALIFY ROW_NUMBER() OVER (ORDER BY "avg_monthly_order_growth" DESC) = 1
),

/* ----------------------------------------------------------
   6)  Month‑over‑month % revenue growth for that category
   ---------------------------------------------------------- */
revenue_growth AS (
    SELECT
        mf."category",
        mf."order_month",
        mf."revenue",
        LAG(mf."revenue") OVER (ORDER BY mf."order_month")   AS "prev_revenue",
        CASE
            WHEN LAG(mf."revenue") OVER (ORDER BY mf."order_month") IS NULL
              OR LAG(mf."revenue") OVER (ORDER BY mf."order_month") = 0
            THEN NULL
            ELSE ( mf."revenue"
                   - LAG(mf."revenue") OVER (ORDER BY mf."order_month") )
                 / LAG(mf."revenue") OVER (ORDER BY mf."order_month") * 100
        END                                                  AS "pct_revenue_growth"
    FROM monthly_facts mf
    JOIN top_category tc
      ON mf."category" = tc."category"
),

/* ----------------------------------------------------------
   7)  Final result – category, avg order growth, avg revenue growth
   ---------------------------------------------------------- */
final AS (
    SELECT
        tc."category",
        tc."avg_monthly_order_growth",
        AVG(rg."pct_revenue_growth")   AS "avg_monthly_revenue_growth"
    FROM top_category   tc
    JOIN revenue_growth rg
      ON tc."category" = rg."category"
    GROUP BY
        tc."category",
        tc."avg_monthly_order_growth"
)

SELECT *
FROM   final;