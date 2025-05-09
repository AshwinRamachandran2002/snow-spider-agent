WITH first_payment AS (
    SELECT
        p.customer_id,
        f.rating,
        ROW_NUMBER() OVER (
            PARTITION BY p.customer_id
            ORDER BY p.payment_date, p.payment_id
        ) AS rn
    FROM payment AS p
    JOIN rental    AS r ON r.rental_id    = p.rental_id
    JOIN inventory AS i ON i.inventory_id = r.inventory_id
    JOIN film      AS f ON f.film_id      = i.film_id
),
customer_first AS (
    SELECT customer_id,
           rating
    FROM first_payment
    WHERE rn = 1
),
customer_totals AS (
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
),
customer_stats AS (
    SELECT
        cf.rating,
        ct.total_spent,
        (cr.total_rentals - 1) AS subsequent_rentals
    FROM customer_first  cf
    JOIN customer_totals ct ON ct.customer_id = cf.customer_id
    JOIN customer_rentals cr ON cr.customer_id = cf.customer_id
)
SELECT
    rating,
    ROUND(AVG(total_spent), 4)        AS avg_total_amount_spent_per_customer,
    ROUND(AVG(subsequent_rentals), 4) AS avg_number_of_subsequent_rentals
FROM customer_stats
GROUP BY rating
ORDER BY rating;