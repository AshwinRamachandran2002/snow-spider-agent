WITH orders_cte AS (
    /* each order linked to its region (via the sales rep) */
    SELECT
        o.id                AS order_id,
        r.id                AS region_id,
        r.name              AS region_name,
        s.id                AS rep_id,
        s.name              AS rep_name,
        o.total_amt_usd     AS order_amt
    FROM web_orders      AS o
    JOIN web_accounts    AS a  ON o.account_id   = a.id
    JOIN web_sales_reps  AS s  ON a.sales_rep_id = s.id
    JOIN web_region      AS r  ON s.region_id    = r.id
),

/* region‑level figures */
region_stats AS (
    SELECT
        region_id,
        region_name,
        COUNT(order_id)                 AS num_orders,
        ROUND(SUM(order_amt),4)         AS total_sales_amt
    FROM orders_cte
    GROUP BY region_id, region_name
),

/* sales per representative within each region */
rep_region_sales AS (
    SELECT
        region_id,
        region_name,
        rep_id,
        rep_name,
        ROUND(SUM(order_amt),4)         AS rep_sales_amt
    FROM orders_cte
    GROUP BY region_id, region_name, rep_id, rep_name
),

/* representatives who achieved the highest sales in their region (ties included) */
top_reps AS (
    SELECT
        rrs.*,
        MAX(rrs.rep_sales_amt) OVER (PARTITION BY region_id) AS max_sales_in_region
    FROM rep_region_sales rrs
)

SELECT
    rs.region_name,
    rs.num_orders,
    rs.total_sales_amt,
    tr.rep_name,
    tr.rep_sales_amt
FROM region_stats rs
JOIN top_reps   tr ON rs.region_id = tr.region_id
WHERE tr.rep_sales_amt = tr.max_sales_in_region
ORDER BY rs.region_name,
         tr.rep_name;