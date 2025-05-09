/*  WEB SALES REPORT – orders & sales per region
    plus every sales rep that ties for the #1 spot inside that region  */

WITH region_totals AS (          -- orders and total sales per region
    SELECT  r.id   AS region_id,
            r.name AS region_name,
            COUNT(o.id)           AS num_orders,
            SUM(o.total_amt_usd)  AS region_total_sales_usd
    FROM   web_region      AS r
    JOIN   web_sales_reps  AS sr ON sr.region_id  = r.id
    JOIN   web_accounts    AS a  ON a.sales_rep_id = sr.id
    JOIN   web_orders      AS o  ON o.account_id   = a.id
    GROUP  BY r.id, r.name
),
rep_totals AS (                  -- total sales for every rep in every region
    SELECT  r.id   AS region_id,
            r.name AS region_name,
            sr.name AS sales_rep_name,
            SUM(o.total_amt_usd) AS rep_total_sales_usd
    FROM    web_region      AS r
    JOIN    web_sales_reps  AS sr ON sr.region_id  = r.id
    JOIN    web_accounts    AS a  ON a.sales_rep_id = sr.id
    JOIN    web_orders      AS o  ON o.account_id   = a.id
    GROUP   BY r.id, r.name, sr.id, sr.name
),
max_rep_by_region AS (           -- highest sales figure in each region
    SELECT  region_id,
            MAX(rep_total_sales_usd) AS max_rep_sales_usd
    FROM    rep_totals
    GROUP   BY region_id
),
top_reps AS (                    -- every rep that hits that max (ties kept)
    SELECT  rt.region_id,
            rt.sales_rep_name,
            rt.rep_total_sales_usd
    FROM    rep_totals        AS rt
    JOIN    max_rep_by_region AS mx
           ON rt.region_id           = mx.region_id
          AND rt.rep_total_sales_usd = mx.max_rep_sales_usd
)

SELECT  rg.region_name,
        rg.num_orders,
        rg.region_total_sales_usd,
        tr.sales_rep_name      AS top_sales_rep_name,
        tr.rep_total_sales_usd AS top_sales_rep_sales_usd
FROM    region_totals AS rg
JOIN    top_reps      AS tr ON tr.region_id = rg.region_id
ORDER BY rg.region_name,
         tr.sales_rep_name;