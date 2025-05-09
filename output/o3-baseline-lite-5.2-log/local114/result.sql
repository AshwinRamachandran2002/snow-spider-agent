WITH order_details AS (
    SELECT
        wo.id                       AS order_id,
        wo.total_amt_usd            AS order_amount,
        wa.sales_rep_id             AS sales_rep_id,
        wr.id                       AS region_id,
        wr.name                     AS region_name
    FROM web_orders      wo
    JOIN web_accounts    wa ON wo.account_id = wa.id
    JOIN web_sales_reps  ws ON wa.sales_rep_id = ws.id
    JOIN web_region      wr ON ws.region_id = wr.id
),

region_summary AS (
    SELECT
        region_id,
        region_name,
        COUNT(order_id)                           AS num_orders,
        ROUND(SUM(order_amount), 4)               AS total_sales_amount
    FROM order_details
    GROUP BY region_id, region_name
),

rep_sales AS (
    SELECT
        od.region_id,
        od.region_name,
        od.sales_rep_id,
        ws.name                                   AS sales_rep_name,
        ROUND(SUM(od.order_amount), 4)            AS rep_total_sales
    FROM order_details  od
    JOIN web_sales_reps ws ON od.sales_rep_id = ws.id
    GROUP BY od.region_id, od.region_name, od.sales_rep_id
),

max_rep_sales AS (
    SELECT
        region_id,
        MAX(rep_total_sales) AS max_sales_in_region
    FROM rep_sales
    GROUP BY region_id
),

top_reps AS (
    SELECT
        rs.region_id,
        rs.region_name,
        rs.sales_rep_name,
        rs.rep_total_sales
    FROM rep_sales rs
    JOIN max_rep_sales mrs
      ON rs.region_id = mrs.region_id
     AND rs.rep_total_sales = mrs.max_sales_in_region
)

SELECT
    r.region_name          AS region,
    r.num_orders,
    r.total_sales_amount,
    t.sales_rep_name       AS top_sales_rep,
    t.rep_total_sales      AS top_rep_sales_amount
FROM region_summary r
JOIN top_reps t
  ON r.region_id = t.region_id
ORDER BY
    r.region_name,
    t.sales_rep_name;