WITH region_stats AS (
    /* total number of orders and total sales per region */
    SELECT
        r."name"                               AS region_name,
        COUNT(o."id")                          AS orders_cnt,
        ROUND(SUM(o."total_amt_usd"), 4)       AS region_sales_usd
    FROM   "web_orders"      AS o
    JOIN   "web_accounts"    AS a  ON o."account_id" = a."id"
    JOIN   "web_sales_reps"  AS sr ON a."sales_rep_id" = sr."id"
    JOIN   "web_region"      AS r  ON sr."region_id"  = r."id"
    GROUP  BY r."name"
),
rep_totals AS (
    /* total sales per (region, sales_rep) */
    SELECT
        r."name"                               AS region_name,
        sr."name"                              AS sales_rep_name,
        ROUND(SUM(o."total_amt_usd"), 4)       AS rep_sales_usd
    FROM   "web_orders"      AS o
    JOIN   "web_accounts"    AS a  ON o."account_id" = a."id"
    JOIN   "web_sales_reps"  AS sr ON a."sales_rep_id" = sr."id"
    JOIN   "web_region"      AS r  ON sr."region_id"  = r."id"
    GROUP  BY r."name", sr."name"
),
rep_max AS (
    /* highest rep sales amount in each region */
    SELECT
        region_name,
        MAX(rep_sales_usd) AS max_sales_usd
    FROM   rep_totals
    GROUP  BY region_name
),
top_reps AS (
    /* keep every rep whose sales equal the regional maximum (ties included) */
    SELECT
        rt.region_name,
        rt.sales_rep_name,
        rt.rep_sales_usd
    FROM   rep_totals rt
    JOIN   rep_max    rm
          ON rt.region_name  = rm.region_name
         AND rt.rep_sales_usd = rm.max_sales_usd
)
SELECT
    rs.region_name,
    rs.orders_cnt,
    rs.region_sales_usd,
    tr.sales_rep_name,
    tr.rep_sales_usd
FROM   region_stats rs
JOIN   top_reps     tr ON rs.region_name = tr.region_name
ORDER BY rs.region_name,
         tr.sales_rep_name;