WITH rep_sales AS (
    /* total dollar sales each rep generated in every region */
    SELECT
        r.id                 AS rep_id,
        r.name               AS rep_name,
        rg.id                AS region_id,
        rg.name              AS region,
        SUM(o.total_amt_usd) AS rep_sales_amt
    FROM web_orders      o
    JOIN web_accounts    a ON o.account_id   = a.id
    JOIN web_sales_reps  r ON a.sales_rep_id = r.id
    JOIN web_region      rg ON r.region_id   = rg.id
    GROUP BY r.id, rg.id
),
max_rep_region AS (
    /* maximum rep‑sales figure within each region */
    SELECT
        region_id,
        MAX(rep_sales_amt) AS max_sales_amt
    FROM rep_sales
    GROUP BY region_id
),
top_reps AS (
    /* all reps who achieved that maximum (handles ties) */
    SELECT
        rs.region_id,
        GROUP_CONCAT(rs.rep_name, ', ') AS top_sales_rep_name,
        rs.rep_sales_amt                AS top_sales_rep_sales_amount
    FROM rep_sales rs
    JOIN max_rep_region mr
      ON rs.region_id     = mr.region_id
     AND rs.rep_sales_amt = mr.max_sales_amt
    GROUP BY rs.region_id
),
region_totals AS (
    /* overall order count and sales amount for each region */
    SELECT
        rg.id                AS region_id,
        rg.name              AS region,
        COUNT(o.id)          AS total_orders,
        SUM(o.total_amt_usd) AS total_sales_amount
    FROM web_orders      o
    JOIN web_accounts    a ON o.account_id   = a.id
    JOIN web_sales_reps  r ON a.sales_rep_id = r.id
    JOIN web_region      rg ON r.region_id   = rg.id
    GROUP BY rg.id
)
SELECT
    rt.region                                         AS region,
    rt.total_orders                                   AS total_orders,
    printf('%.4f', rt.total_sales_amount)             AS total_sales_amount,
    tr.top_sales_rep_name                             AS top_sales_rep_name,
    printf('%.4f', tr.top_sales_rep_sales_amount)     AS top_sales_rep_sales_amount
FROM region_totals rt
LEFT JOIN top_reps tr
       ON rt.region_id = tr.region_id
ORDER BY rt.region;