WITH first_purchases AS (
  SELECT
    "user_id",
    MIN("created_at") AS "first_purchase_at"
  FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
  WHERE
    "status" = 'Complete' AND
    "created_at" <= 1661990399000000  -- up to August 31, 2022
  GROUP BY
    "user_id"
),
user_orders AS (
  SELECT
    o."user_id",
    o."created_at"
  FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" o
  WHERE
    o."status" = 'Complete' AND
    o."created_at" <= 1672531199000000  -- up to December 31, 2022
),
user_orders_with_first_purchase AS (
  SELECT
    u."user_id",
    u."created_at" AS "order_created_at",
    f."first_purchase_at"
  FROM
    user_orders u
    JOIN first_purchases f ON u."user_id" = f."user_id"
),
user_orders_with_month_diff AS (
  SELECT
    "user_id",
    TO_DATE(TO_TIMESTAMP_NTZ("first_purchase_at" / 1e6)) AS "first_purchase_date",
    TO_DATE(TO_TIMESTAMP_NTZ("order_created_at" / 1e6)) AS "order_date",
    DATEDIFF(month, TO_DATE(TO_TIMESTAMP_NTZ("first_purchase_at" / 1e6)), TO_DATE(TO_TIMESTAMP_NTZ("order_created_at" / 1e6))) AS "months_after_first_purchase"
  FROM
    user_orders_with_first_purchase
),
user_purchase_flags AS (
  SELECT
    "user_id",
    "first_purchase_date",
    MAX(CASE WHEN "months_after_first_purchase" = 1 THEN 1 ELSE 0 END) AS "purchase_in_month1",
    MAX(CASE WHEN "months_after_first_purchase" = 2 THEN 1 ELSE 0 END) AS "purchase_in_month2",
    MAX(CASE WHEN "months_after_first_purchase" = 3 THEN 1 ELSE 0 END) AS "purchase_in_month3",
    MAX(CASE WHEN "months_after_first_purchase" = 4 THEN 1 ELSE 0 END) AS "purchase_in_month4"
  FROM
    user_orders_with_month_diff
  GROUP BY
    "user_id",
    "first_purchase_date"
),
user_purchase_flags_with_month AS (
  SELECT
    "user_id",
    TO_CHAR(DATE_TRUNC('MONTH', "first_purchase_date"), 'YYYY-MM') AS "Month_of_First_Purchase",
    "purchase_in_month1",
    "purchase_in_month2",
    "purchase_in_month3",
    "purchase_in_month4"
  FROM
    user_purchase_flags
)
SELECT
  "Month_of_First_Purchase",
  ROUND(100.0 * AVG("purchase_in_month1"), 4) AS "Percentage_Repurchase_in_First_Month",
  ROUND(100.0 * AVG("purchase_in_month2"), 4) AS "Percentage_Repurchase_in_Second_Month",
  ROUND(100.0 * AVG("purchase_in_month3"), 4) AS "Percentage_Repurchase_in_Third_Month",
  ROUND(100.0 * AVG("purchase_in_month4"), 4) AS "Percentage_Repurchase_in_Fourth_Month"
FROM
  user_purchase_flags_with_month
GROUP BY
  "Month_of_First_Purchase"
ORDER BY
  "Month_of_First_Purchase";