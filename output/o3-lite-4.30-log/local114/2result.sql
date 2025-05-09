WITH rep_sales AS (
    /* sales amount per sales‑rep within each region */
    SELECT r."name" AS region,
           sr."id"  AS sales_rep_id,
           sr."name" AS sales_rep_name,
           SUM(o."total_amt_usd") AS sales_amount
    FROM   "web_orders"      AS o
    JOIN   "web_accounts"    AS a  ON a."id" = o."account_id"
    JOIN   "web_sales_reps"  AS sr ON sr."id" = a."sales_rep_id"
    JOIN   "web_region"      AS r  ON r."id" = sr."region_id"
    GROUP  BY r."name", sr."id"
),
region_totals AS (
    /* overall orders and sales per region */
    SELECT r."name"               AS region,
           COUNT(o."id")          AS total_orders,
           SUM(o."total_amt_usd") AS total_sales_amount
    FROM   "web_orders"      AS o
    JOIN   "web_accounts"    AS a  ON a."id" = o."account_id"
    JOIN   "web_sales_reps"  AS sr ON sr."id" = a."sales_rep_id"
    JOIN   "web_region"      AS r  ON r."id" = sr."region_id"
    GROUP  BY r."name"
),
max_rep_sales AS (
    /* highest rep sales amount within each region */
    SELECT region,
           MAX(sales_amount) AS max_sales
    FROM   rep_sales
    GROUP  BY region
),
top_reps AS (
    /* all reps that hit the regional maximum (keeps ties) */
    SELECT rs.region,
           GROUP_CONCAT(rs.sales_rep_name, ', ') AS top_sales_rep_name,
           MAX(rs.sales_amount)                  AS top_sales_rep_sales_amount
    FROM   rep_sales     AS rs
    JOIN   max_rep_sales AS m
           ON  m.region = rs.region
           AND m.max_sales = rs.sales_amount
    GROUP  BY rs.region
)
SELECT rt.region                                   AS region,
       rt.total_orders                             AS total_orders,
       ROUND(rt.total_sales_amount, 4)             AS total_sales_amount,
       tr.top_sales_rep_name                       AS top_sales_rep_name,
       ROUND(tr.top_sales_rep_sales_amount, 4)     AS top_sales_rep_sales_amount
FROM   region_totals AS rt
JOIN   top_reps      AS tr ON tr.region = rt.region
ORDER  BY rt.region;