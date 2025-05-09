WITH orders_enriched AS (
    SELECT
        wr."id"                     AS region_id,
        wr."name"                   AS region_name,
        ws."id"                     AS sales_rep_id,
        ws."name"                   AS sales_rep_name,
        wo."id"                     AS order_id,
        wo."total_amt_usd"          AS order_amount
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ORDERS   wo
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ACCOUNTS wa
      ON wo."account_id" = wa."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_SALES_REPS ws
      ON wa."sales_rep_id" = ws."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_REGION   wr
      ON ws."region_id" = wr."id"
),
region_summary AS (
    SELECT
        region_id,
        region_name,
        COUNT(order_id)               AS num_orders,
        ROUND(SUM(order_amount), 4)   AS total_sales_amount
    FROM orders_enriched
    GROUP BY region_id, region_name
),
rep_region_sales AS (
    SELECT
        region_id,
        region_name,
        sales_rep_id,
        sales_rep_name,
        ROUND(SUM(order_amount), 4)   AS rep_sales_amount
    FROM orders_enriched
    GROUP BY region_id, region_name, sales_rep_id, sales_rep_name
),
rep_rank AS (
    SELECT
        rrs.*,
        MAX(rrs.rep_sales_amount) 
            OVER (PARTITION BY rrs.region_id) AS max_region_sales
    FROM rep_region_sales rrs
),
top_reps AS (
    SELECT
        region_id,
        region_name,
        sales_rep_name,
        rep_sales_amount
    FROM rep_rank
    WHERE rep_sales_amount = max_region_sales   -- include ties
)
SELECT
    rs.region_name,
    rs.num_orders,
    rs.total_sales_amount,
    tr.sales_rep_name,
    tr.rep_sales_amount AS sales_rep_total_amt_usd
FROM region_summary rs
JOIN top_reps tr
  ON rs.region_id = tr.region_id
ORDER BY
    rs.region_name,
    tr.sales_rep_name;