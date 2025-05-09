WITH rep_sales AS (
    /* total sales credited to each rep inside every region */
    SELECT
        wr.name  AS region_name,
        ws.name  AS rep_name,
        SUM(wo.total_amt_usd) AS rep_sales_amount
    FROM   web_orders      AS wo
    JOIN   web_accounts    AS wa ON wo.account_id = wa.id
    JOIN   web_sales_reps  AS ws ON wa.sales_rep_id = ws.id
    JOIN   web_region      AS wr ON ws.region_id   = wr.id
    GROUP  BY wr.name, ws.name
),
region_stats AS (
    /* overall order count and sales dollars per region */
    SELECT
        wr.name              AS region_name,
        COUNT(wo.id)         AS number_of_orders,
        SUM(wo.total_amt_usd) AS total_sales_amount
    FROM   web_orders      AS wo
    JOIN   web_accounts    AS wa ON wo.account_id = wa.id
    JOIN   web_sales_reps  AS ws ON wa.sales_rep_id = ws.id
    JOIN   web_region      AS wr ON ws.region_id   = wr.id
    GROUP  BY wr.name
),
rep_ranks AS (
    /* append each rep’s region‐level maximum to every row */
    SELECT
        rs.region_name,
        rs.rep_name,
        rs.rep_sales_amount,
        MAX(rs.rep_sales_amount) OVER (PARTITION BY rs.region_name) AS region_max_sales
    FROM rep_sales rs
)
SELECT
    rg.region_name,
    rg.number_of_orders,
    rg.total_sales_amount,
    rr.rep_name,
    rr.rep_sales_amount
FROM region_stats rg
JOIN rep_ranks  rr  ON rg.region_name = rr.region_name
WHERE rr.rep_sales_amount = rr.region_max_sales          -- keep only top rep(s) per region
ORDER BY
    rg.region_name,
    rr.rep_name;