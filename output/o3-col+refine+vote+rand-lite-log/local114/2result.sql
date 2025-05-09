WITH orders_region AS (
    SELECT
        wr.name                               AS region_name,
        COUNT(wo.id)                          AS num_orders,
        ROUND(SUM(wo.total_amt_usd), 4)       AS total_sales_amt_usd
    FROM web_orders       AS wo
    JOIN web_accounts     AS wa ON wo.account_id = wa.id
    JOIN web_sales_reps   AS ws ON wa.sales_rep_id = ws.id
    JOIN web_region       AS wr ON ws.region_id = wr.id
    GROUP BY wr.name
),
sales_per_rep_region AS (
    SELECT
        wr.name                               AS region_name,
        ws.name                               AS sales_rep_name,
        ROUND(SUM(wo.total_amt_usd), 4)       AS sales_amount_usd
    FROM web_orders       AS wo
    JOIN web_accounts     AS wa ON wo.account_id = wa.id
    JOIN web_sales_reps   AS ws ON wa.sales_rep_id = ws.id
    JOIN web_region       AS wr ON ws.region_id = wr.id
    GROUP BY wr.name, ws.id
),
max_sales_region AS (
    SELECT
        region_name,
        MAX(sales_amount_usd)                 AS max_sales
    FROM sales_per_rep_region
    GROUP BY region_name
),
top_reps AS (
    SELECT
        spr.region_name,
        spr.sales_rep_name,
        spr.sales_amount_usd
    FROM sales_per_rep_region AS spr
    JOIN max_sales_region    AS msr
      ON  spr.region_name    = msr.region_name
     AND spr.sales_amount_usd = msr.max_sales
)
SELECT
    orr.region_name,
    orr.num_orders,
    orr.total_sales_amt_usd,
    tr.sales_rep_name,
    tr.sales_amount_usd
FROM orders_region AS orr
JOIN top_reps      AS tr
  ON orr.region_name = tr.region_name
ORDER BY
    orr.region_name,
    tr.sales_rep_name;