WITH orders_info AS (
    -- every order labeled with its region and rep
    SELECT  o.id                    AS order_id,
            r.name                  AS region_name,
            sr.name                 AS rep_name,
            o.total_amt_usd         AS order_amount
    FROM        web_orders      AS o
    JOIN        web_accounts    AS a  ON o.account_id  = a.id
    JOIN        web_sales_reps  AS sr ON a.sales_rep_id = sr.id
    JOIN        web_region      AS r  ON sr.region_id   = r.id
),
region_summary AS (
    -- overall orders and sales per region
    SELECT  region_name,
            COUNT(order_id)                        AS num_orders,
            ROUND(SUM(order_amount), 4)            AS total_sales
    FROM    orders_info
    GROUP   BY region_name
),
rep_sales AS (
    -- total sales per rep inside each region
    SELECT  region_name,
            rep_name,
            ROUND(SUM(order_amount), 4)            AS rep_sales
    FROM    orders_info
    GROUP   BY region_name, rep_name
),
max_sales AS (
    -- maximum rep‐sales per region
    SELECT  region_name,
            MAX(rep_sales)                         AS max_rep_sales
    FROM    rep_sales
    GROUP   BY region_name
),
top_reps AS (
    -- all reps who hit the regional maximum (handles ties)
    SELECT  rs.region_name,
            rs.rep_name,
            rs.rep_sales
    FROM        rep_sales  AS rs
    JOIN        max_sales  AS ms
           ON   rs.region_name = ms.region_name
          AND   rs.rep_sales   = ms.max_rep_sales
)
-- final report
SELECT  s.region_name,
        s.num_orders,
        s.total_sales,
        tr.rep_name,
        tr.rep_sales        AS top_rep_sales
FROM        region_summary AS s
JOIN        top_reps       AS tr ON s.region_name = tr.region_name
ORDER BY    s.region_name,
            tr.rep_name;