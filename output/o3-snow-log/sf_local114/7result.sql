WITH orders_with_region AS (
    SELECT
        wr."id"            AS "region_id",
        wr."name"          AS "region_name",
        ws."id"            AS "sales_rep_id",
        ws."name"          AS "sales_rep_name",
        wo."total_amt_usd" AS "total_amt_usd"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ORDERS"     wo
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ACCOUNTS"   wa ON wo."account_id" = wa."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_SALES_REPS" ws ON wa."sales_rep_id" = ws."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_REGION"     wr ON ws."region_id"  = wr."id"
),

region_totals AS (
    SELECT
        "region_id",
        "region_name",
        COUNT(*)                          AS "num_orders",
        ROUND(SUM("total_amt_usd"), 4)    AS "region_total_sales"
    FROM orders_with_region
    GROUP BY "region_id", "region_name"
),

rep_totals AS (
    SELECT
        "region_id",
        "region_name",
        "sales_rep_id",
        "sales_rep_name",
        ROUND(SUM("total_amt_usd"), 4)    AS "rep_total_sales"
    FROM orders_with_region
    GROUP BY "region_id", "region_name", "sales_rep_id", "sales_rep_name"
),

top_reps AS (
    SELECT
        rt.*,
        MAX(rt."rep_total_sales") OVER (PARTITION BY rt."region_id") AS "max_rep_sales"
    FROM rep_totals rt
),

region_top_reps AS (
    SELECT
        tr."region_id",
        tr."region_name",
        tr."sales_rep_name",
        tr."rep_total_sales"
    FROM top_reps tr
    WHERE tr."rep_total_sales" = tr."max_rep_sales"
)

SELECT
    rt."region_name",
    rt."num_orders",
    rt."region_total_sales",
    rtr."sales_rep_name",
    rtr."rep_total_sales"
FROM region_totals rt
JOIN region_top_reps rtr
  ON rt."region_id" = rtr."region_id"
ORDER BY rt."region_name", rtr."sales_rep_name";