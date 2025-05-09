WITH orders_with_region AS (
    SELECT
        o.id                               AS order_id,
        ROUND(o.total_amt_usd,4)           AS order_amt,
        r.id                               AS region_id,
        r.name                             AS region_name,
        sr.id                              AS sales_rep_id,
        sr.name                            AS sales_rep_name
    FROM   web_orders      AS o
    JOIN   web_accounts    AS a   ON o.account_id = a.id
    JOIN   web_sales_reps  AS sr  ON a.sales_rep_id = sr.id
    JOIN   web_region      AS r   ON sr.region_id   = r.id
),
region_summary AS (
    SELECT
        region_id,
        region_name,
        COUNT(order_id)                                 AS orders_count,
        ROUND(SUM(order_amt),4)                         AS region_total_sales
    FROM   orders_with_region
    GROUP  BY region_id, region_name
),
rep_sales AS (
    SELECT
        region_id,
        region_name,
        sales_rep_id,
        sales_rep_name,
        ROUND(SUM(order_amt),4)                         AS rep_total_sales
    FROM   orders_with_region
    GROUP  BY region_id, region_name, sales_rep_id, sales_rep_name
),
rep_rank AS (
    SELECT
        rs.*,
        MAX(rep_total_sales) OVER (PARTITION BY region_id) AS max_region_sales
    FROM   rep_sales rs
),
top_reps AS (
    SELECT
        region_id,
        region_name,
        sales_rep_name,
        rep_total_sales
    FROM   rep_rank
    WHERE  rep_total_sales = max_region_sales            -- keep ties
)
SELECT
    rs.region_name,
    rs.orders_count,
    rs.region_total_sales,
    tr.sales_rep_name,
    tr.rep_total_sales
FROM   region_summary rs
JOIN   top_reps      tr  ON rs.region_id = tr.region_id
ORDER  BY rs.region_name,
          tr.sales_rep_name;