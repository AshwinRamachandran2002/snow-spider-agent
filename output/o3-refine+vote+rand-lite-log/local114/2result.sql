WITH order_details AS (
    SELECT 
        wo.id                         AS order_id,
        wo.total_amt_usd              AS order_total,
        wr.name                       AS region_name,
        ws.id                         AS sales_rep_id,
        ws.name                       AS sales_rep_name
    FROM "web_orders"      wo
    JOIN "web_accounts"    wa ON wo.account_id = wa.id
    JOIN "web_sales_reps"  ws ON wa.sales_rep_id = ws.id
    JOIN "web_region"      wr ON ws.region_id  = wr.id
),

region_summary AS (
    SELECT
        region_name,
        COUNT(order_id)                 AS order_count,
        SUM(order_total)                AS region_total_sales
    FROM order_details
    GROUP BY region_name
),

rep_region_sales AS (
    SELECT
        region_name,
        sales_rep_id,
        sales_rep_name,
        SUM(order_total)                AS rep_total_sales
    FROM order_details
    GROUP BY region_name, sales_rep_id, sales_rep_name
),

max_rep_sales_per_region AS (
    SELECT
        region_name,
        MAX(rep_total_sales)            AS max_rep_total_sales
    FROM rep_region_sales
    GROUP BY region_name
),

top_reps AS (
    SELECT
        rrs.region_name,
        rrs.sales_rep_name,
        rrs.rep_total_sales
    FROM rep_region_sales          rrs
    JOIN max_rep_sales_per_region  mrs
         ON  rrs.region_name     = mrs.region_name
         AND rrs.rep_total_sales = mrs.max_rep_total_sales
)

SELECT
    rs.region_name,
    rs.order_count,
    ROUND(rs.region_total_sales, 4)  AS region_total_sales,
    tr.sales_rep_name                AS top_sales_rep_name,
    ROUND(tr.rep_total_sales, 4)     AS top_rep_sales_amount
FROM region_summary rs
JOIN top_reps       tr ON rs.region_name = tr.region_name
ORDER BY
    rs.region_name,
    tr.sales_rep_name;