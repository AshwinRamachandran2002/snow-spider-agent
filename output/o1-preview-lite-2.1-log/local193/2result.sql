SELECT
  ROUND(AVG(total_ltv), 4) AS "Average_LTV",
  ROUND(AVG(percentage_7_days), 4) || '%' AS "Percentage_First_7_Days",
  ROUND(AVG(percentage_30_days), 4) || '%' AS "Percentage_First_30_Days"
FROM (
  SELECT
    p."customer_id",
    SUM(p."amount") AS total_ltv,
    SUM(CASE
          WHEN p."payment_date" >= i."initial_purchase_date"
           AND p."payment_date" < datetime(i."initial_purchase_date", '+7 days')
          THEN p."amount"
          ELSE 0
        END) AS ltv_7_days,
    SUM(CASE
          WHEN p."payment_date" >= i."initial_purchase_date"
           AND p."payment_date" < datetime(i."initial_purchase_date", '+30 days')
          THEN p."amount"
          ELSE 0
        END) AS ltv_30_days,
    (SUM(CASE
          WHEN p."payment_date" >= i."initial_purchase_date"
           AND p."payment_date" < datetime(i."initial_purchase_date", '+7 days')
          THEN p."amount"
          ELSE 0
        END) * 100.0) / SUM(p."amount") AS percentage_7_days,
    (SUM(CASE
          WHEN p."payment_date" >= i."initial_purchase_date"
           AND p."payment_date" < datetime(i."initial_purchase_date", '+30 days')
          THEN p."amount"
          ELSE 0
        END) * 100.0) / SUM(p."amount") AS percentage_30_days
  FROM "payment" p
  INNER JOIN (
    SELECT
      "customer_id",
      MIN("payment_date") AS "initial_purchase_date"
    FROM "payment"
    GROUP BY "customer_id"
  ) i ON p."customer_id" = i."customer_id"
  GROUP BY p."customer_id"
  HAVING SUM(p."amount") > 0
);