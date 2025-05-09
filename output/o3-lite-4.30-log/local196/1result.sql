WITH first_payment AS (
    SELECT
        p.customer_id,
        f.rating,
        ROW_NUMBER() OVER (PARTITION BY p.customer_id
                           ORDER BY p.payment_date, p.payment_id) AS rn
    FROM payment   AS p
    JOIN rental    AS r ON r.rental_id    = p.rental_id
    JOIN inventory AS i ON i.inventory_id = r.inventory_id
    JOIN film      AS f ON f.film_id      = i.film_id
),
cust_stats AS (
    SELECT
        customer_id,
        SUM(amount)               AS total_spent,
        COUNT(DISTINCT rental_id) AS total_rentals
    FROM payment
    GROUP BY customer_id
),
combined AS (
    SELECT
        fp.rating,
        cs.total_spent,
        cs.total_rentals - 1 AS subsequent_rentals
    FROM first_payment fp
    JOIN cust_stats  cs ON cs.customer_id = fp.customer_id
    WHERE fp.rn = 1
)
SELECT
    rating,
    ROUND(AVG(total_spent), 4)        AS avg_total_spent,
    ROUND(AVG(subsequent_rentals), 4) AS avg_subsequent_rentals
FROM combined
GROUP BY rating
ORDER BY rating;