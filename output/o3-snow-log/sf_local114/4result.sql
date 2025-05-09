WITH orders_region AS (
    SELECT
        R."name"        AS region_name,
        O."id"          AS order_id,
        O."total_amt_usd" AS order_amount,
        S."id"          AS sales_rep_id,
        S."name"        AS sales_rep_name
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ORDERS"       O
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_ACCOUNTS"     A
          ON O."account_id" = A."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_SALES_REPS"   S
          ON A."sales_rep_id" = S."id"
    JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS."WEB_REGION"       R
          ON S."region_id" = R."id"
),
region_stats AS (
    SELECT
        region_name,
        COUNT(order_id)            AS number_of_orders,
        SUM(order_amount)          AS total_sales_amount
    FROM orders_region
    GROUP BY region_name
),
rep_sales AS (
    SELECT
        region_name,
        sales_rep_id,
        sales_rep_name,
        SUM(order_amount)          AS rep_total_sales_amount
    FROM orders_region
    GROUP BY region_name, sales_rep_id, sales_rep_name
),
max_rep_sales AS (
    SELECT
        region_name,
        MAX(rep_total_sales_amount) AS max_sales_amount
    FROM rep_sales
    GROUP BY region_name
),
top_reps AS (
    SELECT
        r.region_name,
        r.sales_rep_name,
        r.rep_total_sales_amount
    FROM rep_sales r
    JOIN max_rep_sales m
         ON r.region_name = m.region_name
        AND r.rep_total_sales_amount = m.max_sales_amount
)
SELECT
    rs.region_name,
    rs.number_of_orders,
    rs.total_sales_amount,
    tr.sales_rep_name,
    tr.rep_total_sales_amount
FROM region_stats rs
JOIN top_reps tr
     ON rs.region_name = tr.region_name
ORDER BY
    rs.region_name,
    tr.sales_rep_name;