WITH
  first_orders AS (
    SELECT
      "user_id",
      MIN("created_at") AS "first_order_date"
    FROM
      THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    GROUP BY
      "user_id"
  ),
  january2020_cohort AS (
    SELECT
      "user_id",
      "first_order_date"
    FROM
      first_orders
    WHERE
      DATE_TRUNC('month', TO_TIMESTAMP_NTZ("first_order_date" / 1e6)) = '2020-01-01'
  ),
  orders_after_first AS (
    SELECT
      o."user_id",
      o."created_at"
    FROM
      THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
      INNER JOIN january2020_cohort c ON o."user_id" = c."user_id"
    WHERE
      o."created_at" > c."first_order_date"
  ),
  monthly_returns AS (
    SELECT
      DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)) AS "order_month",
      o."user_id"
    FROM
      orders_after_first o
    WHERE
      DATE_TRUNC('year', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)) = '2020-01-01'
      AND DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)) >= '2020-02-01'::date
      AND DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)) <= '2020-12-01'::date
    GROUP BY
      1,
      o."user_id"
  ),
  cohort_size AS (
    SELECT
      COUNT(*) AS "cohort_size"
    FROM
      january2020_cohort
  ),
  month_list AS (
    SELECT '2020-02-01'::date AS "month_start" UNION ALL
    SELECT '2020-03-01'::date UNION ALL
    SELECT '2020-04-01'::date UNION ALL
    SELECT '2020-05-01'::date UNION ALL
    SELECT '2020-06-01'::date UNION ALL
    SELECT '2020-07-01'::date UNION ALL
    SELECT '2020-08-01'::date UNION ALL
    SELECT '2020-09-01'::date UNION ALL
    SELECT '2020-10-01'::date UNION ALL
    SELECT '2020-11-01'::date UNION ALL
    SELECT '2020-12-01'::date
  )
SELECT
  TO_CHAR(m."month_start", 'Mon') AS "Month",
  ROUND(
    COALESCE((COUNT(DISTINCT mr."user_id"))::float / cs."cohort_size", 0),
    4
  ) AS "Proportion"
FROM
  month_list m
  LEFT JOIN monthly_returns mr ON mr."order_month" = m."month_start"
  CROSS JOIN cohort_size cs
GROUP BY
  m."month_start",
  cs."cohort_size"
ORDER BY
  m."month_start";