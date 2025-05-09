WITH rep_sales AS (
    /* total sales per sales-rep in each region */
    SELECT
        r."name"                AS region_name,
        s."name"                AS sales_rep_name,
        SUM(o."total_amt_usd")  AS rep_sales
    FROM   "web_orders"     o
    JOIN   "web_accounts"   a  ON o."account_id"  = a."id"
    JOIN   "web_sales_reps" s  ON a."sales_rep_id"= s."id"
    JOIN   "web_region"     r  ON s."region_id"   = r."id"
    GROUP  BY r."name", s."id", s."name"
),
region_agg AS (
    /* overall orders & sales per region */
    SELECT
        r."name"                AS region_name,
        COUNT(DISTINCT o."id")  AS total_orders,
        SUM(o."total_amt_usd")  AS region_sales
    FROM   "web_orders"     o
    JOIN   "web_accounts"   a  ON o."account_id"  = a."id"
    JOIN   "web_sales_reps" s  ON a."sales_rep_id"= s."id"
    JOIN   "web_region"     r  ON s."region_id"   = r."id"
    GROUP  BY r."name"
),
max_sales AS (
    /* highest rep_sales in every region */
    SELECT
        region_name,
        MAX(rep_sales) AS max_rep_sales
    FROM   rep_sales
    GROUP  BY region_name
),
top_reps AS (
    /* keep all reps that reached the regional maximum (ties included) */
    SELECT rs.region_name,
           rs.sales_rep_name,
           rs.rep_sales
    FROM   rep_sales rs
    JOIN   max_sales mx
           ON  rs.region_name = mx.region_name
           AND rs.rep_sales   = mx.max_rep_sales
)
SELECT
    rg.region_name,
    rg.total_orders,
    rg.region_sales,
    GROUP_CONCAT(top.sales_rep_name, ', ') AS top_sales_rep_names,
    MAX(top.rep_sales)                     AS top_sales_amount
FROM   region_agg rg
JOIN   top_reps  top
       ON rg.region_name = top.region_name
GROUP  BY rg.region_name,
          rg.total_orders,
          rg.region_sales
ORDER BY rg.region_name;