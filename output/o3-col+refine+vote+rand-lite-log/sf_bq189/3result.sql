/* ---------------------------------------------------------------------
   1.  Work only with completed order-items
   2.  For every product category
       • build monthly distinct-order counts
       • derive month-over-month % growth
       • average those % growths
   3.  Pick the category with the highest average order-growth
   4.  For that category
       • build monthly revenue
       • derive month-over-month % revenue growth
       • average those % growths
--------------------------------------------------------------------- */

WITH complete_items AS (        -- completed order-items only
    SELECT
        oi."order_id",
        oi."product_id",
        oi."sale_price",
        oi."created_at"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
    WHERE oi."status" = 'Complete'
),

items_with_category AS (        -- attach product category
    SELECT
        p."category",
        ci."order_id",
        ci."sale_price",
        ci."created_at"
    FROM complete_items          ci
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
          ON p."id" = ci."product_id"
),

/* ----------  A.  average MONTHLY % growth in unique-order count  ---------- */
monthly_order_counts AS (       -- distinct-order count per (category, month)
    SELECT
        "category",
        DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1000000))::DATE AS "month",
        COUNT(DISTINCT "order_id")                                      AS "order_cnt"
    FROM items_with_category
    GROUP BY "category", "month"
),

order_pct_growth AS (           -- % growth vs. previous month
    SELECT
        "category",
        "month",
        "order_cnt",
        LAG("order_cnt") OVER (PARTITION BY "category" ORDER BY "month")              AS "prev_cnt",
        ( "order_cnt" - LAG("order_cnt") OVER (PARTITION BY "category" ORDER BY "month") )
            / NULLIF(LAG("order_cnt") OVER (PARTITION BY "category" ORDER BY "month"),0)::FLOAT
                                                                                      AS "pct_growth"
    FROM monthly_order_counts
),

avg_order_growth AS (           -- average of monthly % growths per category
    SELECT
        "category",
        ROUND(AVG("pct_growth"), 4) AS "avg_monthly_order_growth"
    FROM order_pct_growth
    WHERE "pct_growth" IS NOT NULL
    GROUP BY "category"
),

top_category AS (               -- category with the highest average order-growth
    SELECT *
    FROM   avg_order_growth
    ORDER  BY "avg_monthly_order_growth" DESC NULLS LAST
    LIMIT  1
),

/* ----------  B.  average MONTHLY % revenue growth for that category  ---------- */
monthly_revenue AS (            -- monthly revenue for the winning category
    SELECT
        iwc."category",
        DATE_TRUNC('month', TO_TIMESTAMP(iwc."created_at" / 1000000))::DATE AS "month",
        SUM(iwc."sale_price")                                              AS "revenue"
    FROM items_with_category  iwc
    JOIN top_category         tc   ON tc."category" = iwc."category"
    GROUP BY iwc."category", "month"
),

revenue_pct_growth AS (         -- % revenue growth vs. previous month
    SELECT
        "category",
        "month",
        "revenue",
        LAG("revenue") OVER (ORDER BY "month")                                            AS "prev_rev",
        ( "revenue" - LAG("revenue") OVER (ORDER BY "month") )
            / NULLIF(LAG("revenue") OVER (ORDER BY "month"),0)::FLOAT                     AS "pct_rev_growth"
    FROM monthly_revenue
),

avg_revenue_growth AS (         -- average of those revenue growths
    SELECT
        "category",
        ROUND(AVG("pct_rev_growth"), 4) AS "avg_monthly_revenue_growth"
    FROM revenue_pct_growth
    WHERE "pct_rev_growth" IS NOT NULL
    GROUP BY "category"
)

/* ----------  final output  ---------- */
SELECT
    tc."category",
    tc."avg_monthly_order_growth",
    arg."avg_monthly_revenue_growth"
FROM   top_category      tc
JOIN   avg_revenue_growth arg
       ON arg."category" = tc."category";