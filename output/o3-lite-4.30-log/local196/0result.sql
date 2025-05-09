WITH first_payment AS (
    SELECT customer_id,
           MIN(payment_date) AS first_payment_date
    FROM payment
    GROUP BY customer_id
),
first_rating AS (
    SELECT fp.customer_id,
           f.rating
    FROM first_payment fp
    JOIN payment   p ON p.customer_id = fp.customer_id
                    AND p.payment_date = fp.first_payment_date
    JOIN rental    r ON r.rental_id   = p.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film      f ON f.film_id      = i.film_id
),
customer_spend AS (
    SELECT customer_id,
           SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
),
customer_rentals AS (
    SELECT customer_id,
           COUNT(*) AS total_rentals
    FROM rental
    GROUP BY customer_id
)
SELECT fr.rating,
       ROUND(AVG(cs.total_spent), 4)       AS avg_total_spent,
       ROUND(AVG(cr.total_rentals - 1), 4) AS avg_subsequent_rentals
FROM first_rating     fr
JOIN customer_spend   cs ON cs.customer_id = fr.customer_id
JOIN customer_rentals cr ON cr.customer_id = fr.customer_id
GROUP BY fr.rating;