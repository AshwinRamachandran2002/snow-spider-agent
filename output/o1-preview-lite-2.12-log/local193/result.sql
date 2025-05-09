SELECT AVG(t.total_LTV) AS Average_Lifetime_Sales_LTV,
       AVG((t.sales_first_7_days * 100.0) / t.total_LTV) AS Percentage_in_First_7_Days,
       AVG((t.sales_first_30_days * 100.0) / t.total_LTV) AS Percentage_in_First_30_Days
FROM (
    SELECT p.customer_id,
           SUM(p.amount) AS total_LTV,
           SUM(CASE
                   WHEN (strftime('%s', p.payment_date) - strftime('%s', i.initial_purchase_date)) <= 7 * 86400
                   THEN p.amount
                   ELSE 0
               END) AS sales_first_7_days,
           SUM(CASE
                   WHEN (strftime('%s', p.payment_date) - strftime('%s', i.initial_purchase_date)) <= 30 * 86400
                   THEN p.amount
                   ELSE 0
               END) AS sales_first_30_days
    FROM payment p
    JOIN (
        SELECT customer_id, MIN(payment_date) AS initial_purchase_date
        FROM payment
        GROUP BY customer_id
    ) i ON p.customer_id = i.customer_id
    GROUP BY p.customer_id
) t
WHERE t.total_LTV > 0;