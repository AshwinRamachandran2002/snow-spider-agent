WITH first_payment AS (
    /* Earliest payment (i.e. first rental) for every customer */
    SELECT
        customer_id,
        payment_id,
        rental_id,
        payment_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id
                           ORDER BY payment_date, payment_id) AS rn
    FROM payment
),
first_movie AS (
    /* Rating of the movie corresponding to the first payment */
    SELECT
        fp.customer_id,
        f.rating
    FROM first_payment fp
    JOIN rental    r ON r.rental_id    = fp.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film      f ON f.film_id      = i.film_id
    WHERE fp.rn = 1           -- keep only the earliest payment row per customer
),
customer_stats AS (
    /* Total amount spent and total rentals per customer */
    SELECT
        customer_id,
        COUNT(DISTINCT rental_id)            AS total_rentals,
        SUM(amount)                          AS total_amount
    FROM payment
    GROUP BY customer_id
)
SELECT
    fm.rating                                              AS rating,
    ROUND(AVG(cs.total_amount),               4) AS avg_total_amount_per_customer,
    ROUND(AVG(cs.total_rentals - 1),          4) AS avg_subsequent_rentals_per_customer
FROM first_movie     fm
JOIN customer_stats  cs ON cs.customer_id = fm.customer_id
GROUP BY fm.rating
ORDER BY fm.rating;