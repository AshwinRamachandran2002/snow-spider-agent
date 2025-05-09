WITH first_payment AS (          -- earliest payment (i.e. first rental) per customer
    SELECT  p.payment_id,
            p.customer_id,
            p.rental_id,
            p.payment_date,
            ROW_NUMBER() OVER (PARTITION BY p.customer_id
                               ORDER BY p.payment_date, p.payment_id) AS rn
    FROM    payment AS p
),
first_movie AS (                 -- rating of that very first rented film
    SELECT  fp.customer_id,
            f.rating AS first_rating
    FROM    first_payment AS fp
    JOIN    rental      AS r  ON r.rental_id    = fp.rental_id
    JOIN    inventory   AS i  ON i.inventory_id = r.inventory_id
    JOIN    film        AS f  ON f.film_id      = i.film_id
    WHERE   fp.rn = 1
),
customer_stats AS (              -- overall spend and rental count per customer
    SELECT  p.customer_id,
            SUM(p.amount)                          AS total_spent,
            COUNT(DISTINCT p.rental_id)            AS total_rentals
    FROM    payment AS p
    GROUP BY p.customer_id
),
combined AS (                    -- put the pieces together
    SELECT  fm.first_rating,
            cs.total_spent,
            cs.total_rentals
    FROM    first_movie   AS fm
    JOIN    customer_stats AS cs USING (customer_id)
)
SELECT  first_rating                                  AS rating,
        ROUND(AVG(total_spent), 4)                    AS avg_total_amount,
        ROUND(AVG(total_rentals - 1), 4)              AS avg_subsequent_rentals
FROM    combined
GROUP BY first_rating
ORDER BY rating;