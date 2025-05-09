/* Largest month-over-month payment change among the 10 biggest spenders */
SELECT
       mo.customer_id,
       mo.year_month AS month_of_max_change,
       ROUND(mo.diff_amt, 2) AS largest_change
FROM (
     /* Calculate month-over-month differences for the top 10 customers */
     SELECT
            m.customer_id,
            m.year_month,
            ABS(m.month_total -
                LAG(m.month_total) OVER (PARTITION BY m.customer_id
                                          ORDER BY m.year_month)) AS diff_amt
     FROM (
          /* Monthly totals for each of the 10 highest-paying customers */
          SELECT
                 p.customer_id,
                 strftime('%Y-%m', p.payment_date) AS year_month,
                 SUM(p.amount) AS month_total
          FROM payment AS p
          WHERE p.customer_id IN (          -- restrict to top 10 spenders
                SELECT customer_id
                FROM payment
                GROUP BY customer_id
                ORDER BY SUM(amount) DESC
                LIMIT 10)
          GROUP BY p.customer_id, year_month
         ) AS m
    ) AS mo
WHERE mo.diff_amt IS NOT NULL              -- exclude the first month per customer
ORDER BY mo.diff_amt DESC                  -- biggest jump first
LIMIT 1;