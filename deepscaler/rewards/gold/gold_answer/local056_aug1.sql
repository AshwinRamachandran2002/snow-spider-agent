-- Task: Which customer had the highest total payment in a single month? Provide the customer's full name and the month.

WITH monthly_totals AS (
    SELECT
        customer_id,
        strftime('%Y-%m', payment_date) AS payment_month,
        SUM(amount) AS total_payment
    FROM payment
    GROUP BY customer_id, payment_month
)
SELECT
    c.first_name || ' ' || c.last_name AS name,
    mt.payment_month,
    mt.total_payment
FROM monthly_totals mt
JOIN customer c ON mt.customer_id = c.customer_id
ORDER BY mt.total_payment DESC
LIMIT 1;