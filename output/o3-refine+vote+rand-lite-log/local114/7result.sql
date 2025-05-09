WITH orders_with_region AS (
    SELECT
        o.id                              AS order_id,
        r.name                            AS region_name,
        s.id                              AS sales_rep_id,
        s.name                            AS sales_rep_name,
        COALESCE(o.total_amt_usd, 0)      AS order_amount
    FROM web_orders      AS o
    JOIN web_accounts    AS a  ON o.account_id  = a.id
    JOIN web_sales_reps  AS s  ON a.sales_rep_id = s.id
    JOIN web_region      AS r  ON s.region_id    = r.id
),
region_agg AS (
    SELECT
        region_name,
        COUNT(order_id)                    AS orders_count,
        ROUND(SUM(order_amount), 4)        AS region_total_sales
    FROM orders_with_region
    GROUP BY region_name
),
rep_agg AS (
    SELECT
        region_name,
        sales_rep_id,
        sales_rep_name,
        ROUND(SUM(order_amount), 4)        AS rep_total_sales
    FROM orders_with_region
    GROUP BY region_name, sales_rep_id, sales_rep_name
),
max_rep_sales AS (
    SELECT
        region_name,
        MAX(rep_total_sales)               AS max_total_sales
    FROM rep_agg
    GROUP BY region_name
)
SELECT
    ra.region_name                        AS region,
    rg.orders_count,
    rg.region_total_sales,
    ra.sales_rep_name                     AS top_sales_rep_name,
    ra.rep_total_sales                    AS top_sales_rep_total
FROM rep_agg          AS ra
JOIN max_rep_sales    AS mx  ON ra.region_name = mx.region_name
                             AND ra.rep_total_sales = mx.max_total_sales
JOIN region_agg       AS rg  ON ra.region_name = rg.region_name
ORDER BY region, top_sales_rep_name;