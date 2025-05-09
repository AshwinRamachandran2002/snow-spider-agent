WITH rep_sales AS (
    -- total sales per representative within each region
    SELECT  wr.name                     AS region,
            sr.name                     AS rep_name,
            SUM(wo.total_amt_usd)       AS rep_sales
    FROM        web_orders      AS wo
    JOIN        web_accounts    AS wa  ON wo.account_id = wa.id
    JOIN        web_sales_reps  AS sr  ON wa.sales_rep_id = sr.id
    JOIN        web_region      AS wr  ON sr.region_id   = wr.id
    GROUP BY    wr.name, sr.name
),
region_totals AS (
    -- overall order count and sales per region
    SELECT  wr.name               AS region,
            COUNT(wo.id)          AS num_orders,
            SUM(wo.total_amt_usd) AS total_sales
    FROM        web_orders      AS wo
    JOIN        web_accounts    AS wa  ON wo.account_id = wa.id
    JOIN        web_sales_reps  AS sr  ON wa.sales_rep_id = sr.id
    JOIN        web_region      AS wr  ON sr.region_id   = wr.id
    GROUP BY    wr.name
),
max_rep_sales AS (
    -- highest representative sales in each region
    SELECT  region,
            MAX(rep_sales) AS max_sales
    FROM    rep_sales
    GROUP BY region
)
SELECT  rt.region,
        rt.num_orders,
        ROUND(rt.total_sales,4)  AS total_sales,
        rs.rep_name,
        ROUND(rs.rep_sales,4)    AS rep_sales
FROM            region_totals   AS rt
JOIN            max_rep_sales   AS mrs ON rt.region = mrs.region
JOIN            rep_sales       AS rs  ON rs.region = mrs.region
                                         AND rs.rep_sales = mrs.max_sales
ORDER BY        rt.region,
                rs.rep_name;