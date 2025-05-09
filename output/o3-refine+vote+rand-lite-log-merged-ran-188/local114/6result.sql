WITH regional_orders AS (
    /* 1.  Orders count & total sales for every region                   */
    SELECT
        r.id   AS region_id,
        r.name AS region_name,
        COUNT(o.id)                    AS orders_count,
        SUM(o.total_amt_usd)           AS total_region_sales
    FROM web_region       r
    JOIN web_sales_reps   sr ON sr.region_id = r.id
    JOIN web_accounts     a  ON a.sales_rep_id = sr.id
    JOIN web_orders       o  ON o.account_id  = a.id
    GROUP BY r.id, r.name
),
rep_sales AS (
    /* 2.  Total sales per sales‑rep within each region (+rank)          */
    SELECT
        r.id   AS region_id,
        r.name AS region_name,
        sr.id  AS sales_rep_id,
        sr.name AS sales_rep_name,
        SUM(o.total_amt_usd)                         AS rep_total_sales,
        RANK() OVER (PARTITION BY r.id
                     ORDER BY SUM(o.total_amt_usd) DESC) AS sales_rank
    FROM web_region       r
    JOIN web_sales_reps   sr ON sr.region_id = r.id
    JOIN web_accounts     a  ON a.sales_rep_id = sr.id
    JOIN web_orders       o  ON o.account_id  = a.id
    GROUP BY r.id, r.name, sr.id, sr.name
),
top_rep AS (
    /* 3.  Keep only those reps that share the highest sales in region   */
    SELECT
        region_id,
        region_name,
        sales_rep_name,
        rep_total_sales
    FROM rep_sales
    WHERE sales_rank = 1
)
SELECT
    ro.region_name,
    ro.orders_count,
    ro.total_region_sales,
    tr.sales_rep_name       AS top_sales_rep_name,
    tr.rep_total_sales      AS top_sales_rep_sales_amount
FROM regional_orders ro
JOIN top_rep        tr ON tr.region_id = ro.region_id
ORDER BY ro.region_name,
         tr.sales_rep_name;