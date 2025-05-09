WITH first_payment AS (
    SELECT p.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY payment_date) AS rn
    FROM payment AS p
),
first_movie AS (
    SELECT fp.customer_id,
           f.rating
    FROM first_payment AS fp
    JOIN rental    AS r ON r.rental_id    = fp.rental_id
    JOIN inventory AS i ON i.inventory_id = r.inventory_id
    JOIN film      AS f ON f.film_id      = i.film_id
    WHERE fp.rn = 1
),
customer_stats AS (
    SELECT customer_id,
           SUM(amount)                 AS total_spent,
           COUNT(DISTINCT rental_id)   AS total_rentals
    FROM payment
    GROUP BY customer_id
),
combined AS (
    SELECT fm.rating,
           cs.total_spent,
           (cs.total_rentals - 1) AS subsequent_rentals
    FROM first_movie    AS fm
    JOIN customer_stats AS cs USING (customer_id)
)
SELECT rating,
       ROUND(AVG(total_spent),4)        AS avg_total_amount_spent,
       ROUND(AVG(subsequent_rentals),4) AS avg_subsequent_rentals
FROM combined
GROUP BY rating
ORDER BY rating;