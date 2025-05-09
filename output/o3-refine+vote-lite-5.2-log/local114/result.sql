WITH orders_details AS (
    /* connect each order to its region by going through the account’s sales rep */
    SELECT  o.id                AS order_id,
            o.total_amt_usd     AS order_amount,
            sr.region_id,
            sr.id               AS sales_rep_id
    FROM        web_orders      AS o
    JOIN        web_accounts    AS a  ON o.account_id = a.id
    JOIN        web_sales_reps  AS sr ON a.sales_rep_id = sr.id
),
region_sales AS (
    /* overall order count and sales amount per region */
    SELECT  r.id                         AS region_id,
            r.name                       AS region_name,
            COUNT(od.order_id)           AS num_orders,
            SUM(od.order_amount)         AS total_sales_amount
    FROM        orders_details AS od
    JOIN        web_region     AS r  ON od.region_id = r.id
    GROUP BY    r.id, r.name
),
rep_sales AS (
    /* total sales amount per rep inside each region */
    SELECT  od.region_id,
            od.sales_rep_id,
            SUM(od.order_amount)         AS rep_total_sales
    FROM    orders_details AS od
    GROUP BY od.region_id, od.sales_rep_id
),
max_rep_sales AS (
    /* highest rep sales amount in each region */
    SELECT  region_id,
            MAX(rep_total_sales) AS max_sales
    FROM    rep_sales
    GROUP BY region_id
),
top_reps AS (
    /* reps whose sales equal the regional maximum (handles ties) */
    SELECT  rs.region_id,
            rs.sales_rep_id,
            rs.rep_total_sales
    FROM        rep_sales     AS rs
    JOIN        max_rep_sales AS m
           ON   rs.region_id = m.region_id
          AND   rs.rep_total_sales = m.max_sales
)
SELECT  rg.region_name,
        rg.num_orders,
        rg.total_sales_amount,
        sr.name             AS top_rep_name,
        tr.rep_total_sales  AS top_rep_sales_amount
FROM        region_sales  AS rg
JOIN        top_reps      AS tr ON rg.region_id = tr.region_id
JOIN        web_sales_reps AS sr ON tr.sales_rep_id = sr.id
ORDER BY    rg.region_name,
            sr.name;