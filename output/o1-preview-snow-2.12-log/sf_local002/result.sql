WITH RECURSIVE date_sequence AS (
  SELECT '2017-01-01'::DATE AS "order_date", 1 AS "day_number"
  UNION ALL
  SELECT DATEADD('day', 1, "order_date") AS "order_date", "day_number" + 1 AS "day_number"
  FROM date_sequence
  WHERE "order_date" < '2018-08-29'::DATE
),
daily_toy_sales AS (
  SELECT
    DATE(o."order_purchase_timestamp") AS "order_date",
    SUM(oi."price") AS "daily_toy_sales"
  FROM
    "E_COMMERCE"."E_COMMERCE"."ORDERS" o
    JOIN "E_COMMERCE"."E_COMMERCE"."ORDER_ITEMS" oi
      ON o."order_id" = oi."order_id"
    JOIN "E_COMMERCE"."E_COMMERCE"."PRODUCTS" p
      ON oi."product_id" = p."product_id"
    JOIN "E_COMMERCE"."E_COMMERCE"."PRODUCT_CATEGORY_NAME_TRANSLATION" t
      ON p."product_category_name" = t."product_category_name"
  WHERE
    t."product_category_name_english" = 'toys'
    AND o."order_purchase_timestamp" BETWEEN '2017-01-01' AND '2018-08-29'
  GROUP BY
    DATE(o."order_purchase_timestamp")
),
full_daily_sales AS (
  SELECT
    d."order_date",
    COALESCE(s."daily_toy_sales", 0) AS "daily_toy_sales",
    d."day_number"
  FROM
    date_sequence d
    LEFT JOIN daily_toy_sales s
      ON d."order_date" = s."order_date"
),
regression_coefficients AS (
  SELECT
    REGR_SLOPE("daily_toy_sales", "day_number") AS "slope",
    REGR_INTERCEPT("daily_toy_sales", "day_number") AS "intercept"
  FROM
    full_daily_sales
),
predicted_date_sequence AS (
  SELECT '2018-12-03'::DATE AS "order_date", DATEDIFF('day', '2017-01-01', '2018-12-03'::DATE) + 1 AS "day_number"
  UNION ALL
  SELECT DATEADD('day', 1, "order_date") AS "order_date", "day_number" + 1 AS "day_number"
  FROM predicted_date_sequence
  WHERE "order_date" < '2018-12-10'::DATE
),
predicted_sales AS (
  SELECT
    pds."order_date",
    pds."day_number",
    rc."slope" * pds."day_number" + rc."intercept" AS "predicted_sales"
  FROM
    predicted_date_sequence pds
    CROSS JOIN regression_coefficients rc
),
moving_averages AS (
  SELECT
    p1."order_date",
    AVG(p2."predicted_sales") AS "5-Day Symmetric Moving Average"
  FROM
    predicted_sales p1
    JOIN predicted_sales p2
      ON p2."day_number" BETWEEN p1."day_number" - 2 AND p1."day_number" + 2
  WHERE
    p1."order_date" BETWEEN '2018-12-05' AND '2018-12-08'
  GROUP BY
    p1."order_date"
),
total_sum AS (
  SELECT
    SUM("5-Day Symmetric Moving Average") AS "Total Sum"
  FROM
    moving_averages
)
SELECT
  TO_CHAR("order_date", 'YYYY-MM-DD') AS "Date",
  ROUND("5-Day Symmetric Moving Average", 4)::VARCHAR AS "5-Day Symmetric Moving Average"
FROM
  moving_averages
UNION ALL
SELECT
  'Total Sum' AS "Date",
  ROUND("Total Sum", 4)::VARCHAR AS "5-Day Symmetric Moving Average"
FROM
  total_sum
ORDER BY
  CASE WHEN "Date" = 'Total Sum' THEN 2 ELSE 1 END,
  "Date";