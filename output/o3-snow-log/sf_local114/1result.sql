WITH orders_details AS (
    SELECT
        r."id"                              AS region_id,
        r."name"                            AS region_name,
        sr."id"                             AS sales_rep_id,
        sr."name"                           AS sales_rep_name,
        o."id"                              AS order_id,
        o."total_amt_usd"                   AS order_amount
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ORDERS       AS o
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_ACCOUNTS     AS a
      ON o."account_id" = a."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_SALES_REPS   AS sr
      ON a."sales_rep_id" = sr."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.WEB_REGION       AS r
      ON sr."region_id" = r."id"
),
region_summary AS (
    SELECT
        region_id,
        region_name,
        COUNT(DISTINCT order_id)                              AS order_count,
        ROUND(SUM(order_amount), 4)                           AS region_total_sales
    FROM orders_details
    GROUP BY region_id, region_name
),
rep_sales AS (
    SELECT
        region_id,
        sales_rep_id,
        MAX(sales_rep_name)                                   AS sales_rep_name,
        ROUND(SUM(order_amount), 4)                           AS rep_total_sales
    FROM orders_details
    GROUP BY region_id, sales_rep_id
),
top_rep_per_region AS (
    SELECT
        rs.region_id,
        rs.sales_rep_id,
        rs.sales_rep_name,
        rs.rep_total_sales
    FROM rep_sales rs
    JOIN (
        SELECT
            region_id,
            MAX(rep_total_sales) AS max_sales
        FROM rep_sales
        GROUP BY region_id
    ) mx
      ON rs.region_id      = mx.region_id
     AND rs.rep_total_sales = mx.max_sales
)
SELECT
    s.region_name,
    s.order_count,
    s.region_total_sales,
    t.sales_rep_name,
    t.rep_total_sales
FROM region_summary          AS s
JOIN top_rep_per_region      AS t
  ON s.region_id = t.region_id
ORDER BY
    s.region_name,
    t.sales_rep_name NULLS LAST;