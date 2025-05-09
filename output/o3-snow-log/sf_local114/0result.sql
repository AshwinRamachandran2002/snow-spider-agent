WITH region_totals AS (          -- 1. Orders & sales per region
    SELECT
        r."id"                       AS region_id,
        r."name"                     AS region_name,
        COUNT(o."id")                AS num_orders,
        SUM(o."total_amt_usd")       AS total_sales_amount
    FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_ORDERS"       o
    JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_ACCOUNTS"     a  ON o."account_id"   = a."id"
    JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_SALES_REPS"   sr ON a."sales_rep_id" = sr."id"
    JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_REGION"       r  ON sr."region_id"   = r."id"
    GROUP BY r."id", r."name"
),

rep_totals AS (               -- 2. Sales per rep within each region
    SELECT
        r."id"                 AS region_id,
        sr."id"                AS sales_rep_id,
        sr."name"              AS sales_rep_name,
        SUM(o."total_amt_usd") AS rep_sales_amount
    FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_ORDERS"       o
    JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_ACCOUNTS"     a  ON o."account_id"   = a."id"
    JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_SALES_REPS"   sr ON a."sales_rep_id" = sr."id"
    JOIN "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."WEB_REGION"       r  ON sr."region_id"   = r."id"
    GROUP BY r."id", sr."id", sr."name"
),

top_reps AS (                 -- 3. Highest-selling rep(s) per region (handle ties)
    SELECT
        region_id,
        sales_rep_name,
        rep_sales_amount
    FROM (
        SELECT
            rt.*,
            MAX(rt.rep_sales_amount) OVER (PARTITION BY rt.region_id) AS max_region_sales
        FROM rep_totals rt
    )
    WHERE rep_sales_amount = max_region_sales
)

-- 4. Final report: region totals + top rep(s)
SELECT
    rt.region_name,
    rt.num_orders,
    rt.total_sales_amount,
    tr.sales_rep_name,
    tr.rep_sales_amount
FROM region_totals rt
JOIN top_reps     tr ON rt.region_id = tr.region_id
ORDER BY rt.region_name, tr.sales_rep_name;