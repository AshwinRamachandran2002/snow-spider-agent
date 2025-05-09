SELECT
  ROUND(AVG(total_ltv), 4) AS average_ltv,
  ROUND(AVG(percentage_first_7_days), 4) || '%' AS percentage_first_7_days,
  ROUND(AVG(percentage_first_30_days), 4) || '%' AS percentage_first_30_days
FROM (
  SELECT
    p.customer_id,
    SUM(p.amount) AS total_ltv,
    (SUM(CASE WHEN p.payment_date < datetime(fp.first_purchase_date, '+7 days') THEN p.amount ELSE 0 END) * 100.0 / SUM(p.amount)) AS percentage_first_7_days,
    (SUM(CASE WHEN p.payment_date < datetime(fp.first_purchase_date, '+30 days') THEN p.amount ELSE 0 END) * 100.0 / SUM(p.amount)) AS percentage_first_30_days
  FROM payment p
  JOIN (
    SELECT customer_id, MIN(payment_date) AS first_purchase_date
    FROM payment
    GROUP BY customer_id
  ) fp ON p.customer_id = fp.customer_id
  GROUP BY p.customer_id
  HAVING total_ltv > 0
) sub;