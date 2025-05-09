WITH first_payment AS (
    SELECT
        p.customer_id,
        p.payment_id,
        p.rental_id,
        ROW_NUMBER() OVER (
            PARTITION BY p.customer_id
            ORDER BY p.payment_date, p.payment_id
        ) AS rn
    FROM payment AS p
),
first_payment_selected AS (
    SELECT
        customer_id,
        rental_id
    FROM first_payment
    WHERE rn = 1
),
customer_totals AS (
    SELECT
        customer_id,
        SUM(amount) AS total_amount
    FROM payment
    GROUP BY customer_id
),
customer_rentals AS (
    SELECT
        customer_id,
        COUNT(*) AS total_rentals
    FROM rental
    GROUP BY customer_id
),
customer_first_rating AS (
    SELECT
        fps.customer_id,
        f.rating,
        ct.total_amount,
        cr.total_rentals
    FROM first_payment_selected AS fps
    JOIN rental      AS r  ON r.rental_id      = fps.rental_id
    JOIN inventory   AS i  ON i.inventory_id   = r.inventory_id
    JOIN film        AS f  ON f.film_id        = i.film_id
    JOIN customer_totals  AS ct ON ct.customer_id = fps.customer_id
    JOIN customer_rentals AS cr ON cr.customer_id = fps.customer_id
)
SELECT
    rating,
    AVG(total_amount)           AS avg_total_amount_spent_per_customer,
    AVG(total_rentals - 1)      AS avg_subsequent_rentals
FROM customer_first_rating
GROUP BY rating
ORDER BY rating;