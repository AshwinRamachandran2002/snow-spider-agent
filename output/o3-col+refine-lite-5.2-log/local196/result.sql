WITH first_payment AS (
    SELECT customer_id,
           MIN(payment_date) AS first_payment_date
    FROM payment
    GROUP BY customer_id
),
first_film AS (
    SELECT fp.customer_id,
           f.rating
    FROM first_payment fp
    JOIN payment  p ON p.customer_id = fp.customer_id
                  AND p.payment_date = fp.first_payment_date
    JOIN rental   r ON r.rental_id   = p.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film     f ON f.film_id     = i.film_id
),
customer_totals AS (
    SELECT p.customer_id,
           SUM(p.amount)                       AS total_amount_spent,
           COUNT(DISTINCT r.rental_id)         AS total_rentals
    FROM payment p
    JOIN rental  r ON r.rental_id = p.rental_id
    GROUP BY p.customer_id
),
customer_metrics AS (
    SELECT ff.customer_id,
           ff.rating                AS first_rating,
           ct.total_amount_spent,
           (ct.total_rentals - 1)   AS subsequent_rentals
    FROM first_film       ff
    JOIN customer_totals  ct ON ct.customer_id = ff.customer_id
)
SELECT first_rating              AS rating,
       AVG(total_amount_spent)   AS avg_total_amount_spent,
       AVG(subsequent_rentals)   AS avg_subsequent_rentals
FROM customer_metrics
GROUP BY first_rating;