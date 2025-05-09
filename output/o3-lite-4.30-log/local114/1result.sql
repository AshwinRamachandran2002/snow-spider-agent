WITH region_totals AS (
    SELECT
        r."name"                         AS region,
        COUNT(o."id")                    AS total_orders,
        ROUND(SUM(o."total_amt_usd"), 4) AS total_sales_amount
    FROM "web_orders"       AS o
    JOIN "web_accounts"     AS a  ON o."account_id"   = a."id"
    JOIN "web_sales_reps"   AS sr ON a."sales_rep_id" = sr."id"
    JOIN "web_region"       AS r  ON sr."region_id"   = r."id"
    GROUP BY r."name"
),
rep_sales AS (
    SELECT
        r."name"                         AS region,
        sr."name"                        AS rep_name,
        ROUND(SUM(o."total_amt_usd"),4)  AS rep_sales
    FROM "web_orders"       AS o
    JOIN "web_accounts"     AS a  ON o."account_id"   = a."id"
    JOIN "web_sales_reps"   AS sr ON a."sales_rep_id" = sr."id"
    JOIN "web_region"       AS r  ON sr."region_id"   = r."id"
    GROUP BY r."name", sr."name"
),
max_rep_sales AS (
    SELECT
        region,
        MAX(rep_sales) AS top_rep_sales_amount
    FROM rep_sales
    GROUP BY region
)
SELECT
    rt.region,
    rt.total_orders,
    rt.total_sales_amount,
    rs.rep_name                 AS top_sales_rep_name,
    rs.rep_sales                AS top_sales_rep_sales_amount
FROM region_totals AS rt
JOIN max_rep_sales AS mx ON rt.region = mx.region
JOIN rep_sales     AS rs ON rs.region = mx.region
                         AND rs.rep_sales = mx.top_rep_sales_amount
ORDER BY rt.region, rs.rep_name;