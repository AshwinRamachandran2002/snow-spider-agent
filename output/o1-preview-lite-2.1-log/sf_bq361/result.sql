WITH first_orders AS (
  SELECT "user_id", MIN("created_at") AS first_order_at
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
  GROUP BY "user_id"
),
january_users AS (
  SELECT fo."user_id", fo.first_order_at
  FROM first_orders fo
  WHERE TO_TIMESTAMP_NTZ(fo.first_order_at / 1000000) >= '2020-01-01' AND TO_TIMESTAMP_NTZ(fo.first_order_at / 1000000) < '2020-02-01'
),
months AS (
  SELECT DATEADD(month, (ROW_NUMBER() OVER (ORDER BY seq4())) - 1, TO_DATE('2020-02-01')) AS month_start
  FROM table(generator(rowcount => 11))
),
subsequent_orders AS (
  SELECT o."user_id",
         DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1000000)) AS order_month
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
  INNER JOIN january_users ju ON o."user_id" = ju."user_id"
  WHERE TO_TIMESTAMP_NTZ(o."created_at" / 1000000) >= '2020-02-01' AND TO_TIMESTAMP_NTZ(o."created_at" / 1000000) < '2021-01-01'
    AND o."created_at" > ju.first_order_at
)
SELECT
  TO_CHAR(months.month_start, 'Mon') AS "Month",
  ROUND(COALESCE(COUNT(DISTINCT subsequent_orders."user_id"), 0) / (SELECT COUNT(DISTINCT "user_id") FROM january_users), 4) AS "Proportion"
FROM months
LEFT JOIN subsequent_orders ON months.month_start = subsequent_orders.order_month
GROUP BY months.month_start
ORDER BY months.month_start;