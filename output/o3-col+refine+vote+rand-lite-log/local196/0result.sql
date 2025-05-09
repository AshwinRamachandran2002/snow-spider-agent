WITH first_film AS (           -- rating of the very first film each customer paid for
    SELECT  p.customer_id,
            f.rating,
            MIN(p.payment_date) AS first_payment_date
    FROM    payment   AS p
    JOIN    rental    AS r  ON r.rental_id    = p.rental_id
    JOIN    inventory AS i  ON i.inventory_id = r.inventory_id
    JOIN    film      AS f  ON f.film_id      = i.film_id
    GROUP BY p.customer_id
),
customer_spend AS (            -- total amount every customer has spent
    SELECT  customer_id,
            SUM(amount) AS total_amount_spent
    FROM    payment
    GROUP BY customer_id
),
customer_rentals AS (          -- total rentals per customer
    SELECT  customer_id,
            COUNT(*) AS total_rentals
    FROM    rental
    GROUP BY customer_id
),
customer_summary AS (          -- combine all per-customer metrics
    SELECT  ff.customer_id,
            ff.rating,
            cs.total_amount_spent,
            (cr.total_rentals - 1) AS subsequent_rentals
    FROM    first_film       AS ff
    JOIN    customer_spend   AS cs USING (customer_id)
    JOIN    customer_rentals AS cr USING (customer_id)
)
SELECT  rating,
        ROUND(AVG(total_amount_spent), 4)   AS avg_total_amount_spent,
        ROUND(AVG(subsequent_rentals), 4)   AS avg_subsequent_rentals
FROM    customer_summary
GROUP BY rating
ORDER BY rating;