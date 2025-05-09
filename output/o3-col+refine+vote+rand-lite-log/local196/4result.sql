WITH first_payment AS (
    SELECT 
        customer_id,
        MIN(payment_date) AS first_payment_date
    FROM payment
    GROUP BY customer_id
),
first_movie AS (
    /* rating of the movie involved in each customer's very first payment */
    SELECT 
        fp.customer_id,
        MIN(f.rating) AS rating      -- MIN() just breaks any potential tie on the same timestamp
    FROM first_payment fp
    JOIN payment   p ON p.customer_id = fp.customer_id
                    AND p.payment_date = fp.first_payment_date
    JOIN rental    r ON r.rental_id   = p.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film      f ON f.film_id      = i.film_id
    GROUP BY fp.customer_id
),
customer_spent AS (
    SELECT 
        customer_id,
        SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
),
rental_count AS (
    SELECT 
        customer_id,
        COUNT(*) AS total_rentals
    FROM rental
    GROUP BY customer_id
),
customer_summary AS (
    SELECT 
        fm.rating,
        cs.total_spent,
        rc.total_rentals - 1 AS subsequent_rentals
    FROM first_movie    fm
    JOIN customer_spent cs ON cs.customer_id = fm.customer_id
    JOIN rental_count   rc ON rc.customer_id = fm.customer_id
)
SELECT
    rating AS first_movie_rating,
    ROUND(AVG(total_spent), 4)        AS avg_total_spent,
    ROUND(AVG(subsequent_rentals), 4) AS avg_subsequent_rentals
FROM customer_summary
GROUP BY rating
ORDER BY rating;