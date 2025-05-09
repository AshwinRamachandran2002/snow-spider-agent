WITH orders_with_region AS (
    SELECT
        o.id                AS order_id,
        o.total_amt_usd     AS order_amount,
        s.id                AS sales_rep_id,
        s.name              AS sales_rep_name,
        r.id                AS region_id,
        r.name              AS region_name
    FROM  web_orders      o
    JOIN  web_accounts    a ON o.account_id = a.id
    JOIN  web_sales_reps  s ON a.sales_rep_id = s.id
    JOIN  web_region      r ON s.region_id   = r.id
),
region_stats AS (
    /* total number of orders and total sales for every region */
    SELECT
        region_id,
        region_name,
        COUNT(order_id)              AS total_orders,
        ROUND(SUM(order_amount),4)   AS region_total_sales
    FROM orders_with_region
    GROUP BY region_id
),
rep_stats AS (
    /* total sales amount for every sales rep inside every region */
    SELECT
        region_id,
        region_name,
        sales_rep_id,
        sales_rep_name,
        ROUND(SUM(order_amount),4)   AS rep_total_sales
    FROM orders_with_region
    GROUP BY region_id, sales_rep_id
),
rep_ranked AS (
    /* find the highest‐selling rep(s) per region */
    SELECT
        rs.*,
        MAX(rep_total_sales) OVER (PARTITION BY region_id) AS region_max_sales
    FROM rep_stats rs
),
top_reps AS (
    SELECT *
    FROM   rep_ranked
    WHERE  rep_total_sales = region_max_sales   -- keep all ties
)
SELECT
    rg.region_name                AS region,
    rg.total_orders               AS number_of_orders,
    rg.region_total_sales         AS total_sales_amount,
    tr.sales_rep_name             AS top_sales_rep_name,
    tr.rep_total_sales            AS top_sales_rep_sales_amount
FROM   region_stats rg
JOIN   top_reps     tr  ON rg.region_id = tr.region_id
ORDER  BY rg.region_name, tr.sales_rep_name;