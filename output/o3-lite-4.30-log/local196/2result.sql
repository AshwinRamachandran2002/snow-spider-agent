WITH payment_film AS (
    SELECT  p.payment_id,
            p.customer_id,
            p.amount,
            p.payment_date,
            r.rental_id,
            f.rating,
            ROW_NUMBER() OVER (
                PARTITION BY p.customer_id
                ORDER BY p.payment_date, p.payment_id
            ) AS rn
    FROM   payment   AS p
    JOIN   rental    AS r ON r.rental_id    = p.rental_id
    JOIN   inventory AS i ON i.inventory_id = r.inventory_id
    JOIN   film      AS f ON f.film_id      = i.film_id
),
first_movie AS (
    SELECT customer_id,
           rating
    FROM   payment_film
    WHERE  rn = 1
),
customer_totals AS (
    SELECT customer_id,
           SUM(amount)               AS total_amount,
           COUNT(DISTINCT rental_id) AS total_rentals
    FROM   payment_film
    GROUP BY customer_id
),
combined AS (
    SELECT fm.rating,
           ct.total_amount,
           ct.total_rentals - 1      AS subsequent_rentals
    FROM   first_movie     AS fm
    JOIN   customer_totals AS ct USING (customer_id)
)
SELECT  rating,
        ROUND(AVG(total_amount), 4)      AS avg_total_spent,
        ROUND(AVG(subsequent_rentals),4) AS avg_subsequent_rentals
FROM    combined
GROUP BY rating
ORDER BY rating;