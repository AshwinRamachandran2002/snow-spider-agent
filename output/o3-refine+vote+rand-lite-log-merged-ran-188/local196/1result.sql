WITH first_payment AS (
    SELECT
        p.payment_id,
        p.customer_id,
        p.rental_id,
        p.amount,
        p.payment_date,
        ROW_NUMBER() OVER (PARTITION BY p.customer_id
                           ORDER BY p.payment_date, p.payment_id) AS rn
    FROM payment AS p
),
first_movie AS (
    SELECT
        fp.customer_id,
        f.rating
    FROM first_payment AS fp
    JOIN rental    AS r ON r.rental_id    = fp.rental_id
    JOIN inventory AS i ON i.inventory_id = r.inventory_id
    JOIN film      AS f ON f.film_id      = i.film_id
    WHERE fp.rn = 1
),
customer_stats AS (
    SELECT
        p.customer_id,
        SUM(p.amount) AS total_amount,
        COUNT(*)      AS total_rentals
    FROM payment AS p
    GROUP BY p.customer_id
),
combined AS (
    SELECT
        fm.rating,
        cs.total_amount,
        cs.total_rentals - 1 AS subsequent_rentals
    FROM first_movie    AS fm
    JOIN customer_stats AS cs
      ON cs.customer_id = fm.customer_id
)
SELECT
    rating,
    ROUND(AVG(total_amount), 4)      AS avg_total_amount_per_customer,
    ROUND(AVG(subsequent_rentals),4) AS avg_subsequent_rentals
FROM combined
GROUP BY rating
ORDER BY rating;