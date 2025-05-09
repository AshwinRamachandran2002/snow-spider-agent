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
    JOIN payment  p ON p.customer_id = fp.customer_id
                   AND p.payment_date = fp.first_payment_date
    JOIN rental   r ON r.rental_id   = p.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film      f ON f.film_id      = i.film_id
),
customer_stats AS (
    SELECT customer_id,
           SUM(amount)                       AS total_amount,
           COUNT(DISTINCT rental_id)         AS total_rentals
    FROM payment
    GROUP BY customer_id
)
SELECT fr.rating                              AS first_movie_rating,
       ROUND(AVG(cs.total_amount), 2)         AS avg_total_amount_per_customer,
       ROUND(AVG(cs.total_rentals - 1), 2)    AS avg_subsequent_rentals_per_customer
FROM first_rating     fr
JOIN customer_stats   cs ON cs.customer_id = fr.customer_id
GROUP BY fr.rating;