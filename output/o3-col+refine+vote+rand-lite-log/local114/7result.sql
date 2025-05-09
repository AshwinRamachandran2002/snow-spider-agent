WITH rep_sales AS (          -- total sales per rep in each region
        SELECT  r."name"  AS region_name,
                sr."name" AS sales_rep_name,
                SUM(o."total_amt_usd") AS rep_total_sales_usd
        FROM   "web_orders"      o
        JOIN   "web_accounts"    a  ON o."account_id"   = a."id"
        JOIN   "web_sales_reps"  sr ON a."sales_rep_id" = sr."id"
        JOIN   "web_region"      r  ON sr."region_id"   = r."id"
        GROUP  BY r."name", sr."name"
),
max_rep_sales AS (           -- maximum rep-sales value per region
        SELECT  region_name,
                MAX(rep_total_sales_usd) AS max_sales_usd
        FROM    rep_sales
        GROUP   BY region_name
),
top_reps AS (                -- keep ALL reps that reach the maximum
        SELECT  rs.region_name,
                rs.sales_rep_name,
                rs.rep_total_sales_usd
        FROM    rep_sales rs
        JOIN    max_rep_sales m
               ON rs.region_name = m.region_name
              AND rs.rep_total_sales_usd = m.max_sales_usd
),
region_totals AS (           -- order count & total sales per region
        SELECT  r."name"  AS region_name,
                COUNT(*)  AS num_orders,
                SUM(o."total_amt_usd") AS total_sales_usd
        FROM   "web_orders"      o
        JOIN   "web_accounts"    a  ON o."account_id"   = a."id"
        JOIN   "web_sales_reps"  sr ON a."sales_rep_id" = sr."id"
        JOIN   "web_region"      r  ON sr."region_id"   = r."id"
        GROUP  BY r."name"
)
SELECT  rt.region_name                 AS "Region",
        rt.num_orders                  AS "Number_of_Orders",
        ROUND(rt.total_sales_usd,4)    AS "Total_Sales_USD",
        tr.sales_rep_name              AS "Top_Sales_Rep",
        ROUND(tr.rep_total_sales_usd,4)AS "Rep_Total_Sales_USD"
FROM    region_totals rt
JOIN    top_reps tr
       ON rt.region_name = tr.region_name
ORDER  BY rt.region_name, tr.sales_rep_name;