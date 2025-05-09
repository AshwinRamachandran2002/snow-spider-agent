WITH order_data AS (
    /* bring every order together with its sales‑rep and region */
    SELECT  o.id                          AS order_id,
            o.total_amt_usd               AS order_amount,
            a.sales_rep_id,
            sr.region_id
    FROM            web_orders      AS o
    JOIN            web_accounts    AS a  ON o.account_id = a.id
    JOIN            web_sales_reps  AS sr ON a.sales_rep_id = sr.id
),

region_stats AS (
    /* overall order count and sales per region */
    SELECT  r.id                         AS region_id,
            r.name                       AS region_name,
            COUNT(od.order_id)           AS orders_count,
            ROUND(SUM(od.order_amount),4) AS region_total_sales
    FROM            order_data   AS od
    JOIN            web_region   AS r  ON od.region_id = r.id
    GROUP BY        r.id, r.name
),

rep_region_sales AS (
    /* total sales per (rep, region) */
    SELECT  od.region_id,
            od.sales_rep_id,
            sr.name                      AS sales_rep_name,
            SUM(od.order_amount)         AS rep_sales
    FROM            order_data      AS od
    JOIN            web_sales_reps  AS sr ON od.sales_rep_id = sr.id
    GROUP BY        od.region_id, od.sales_rep_id
),

max_rep_sales AS (
    /* highest rep sales figure in each region */
    SELECT  region_id,
            MAX(rep_sales) AS max_sales
    FROM    rep_region_sales
    GROUP BY region_id
)

SELECT  rs.region_name,
        rs.orders_count,
        rs.region_total_sales,
        rrs.sales_rep_name,
        ROUND(rrs.rep_sales,4) AS sales_rep_sales
FROM            region_stats     AS rs
JOIN            max_rep_sales    AS mx  ON rs.region_id = mx.region_id
JOIN            rep_region_sales AS rrs ON  rrs.region_id = mx.region_id
                                         AND rrs.rep_sales = mx.max_sales
ORDER BY        rs.region_name,
                rrs.sales_rep_name;