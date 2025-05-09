WITH first_payment AS (       -- locate the very first payment of every customer
    SELECT  p.payment_id,
            p.customer_id,
            p.rental_id,
            ROW_NUMBER() OVER (PARTITION BY p.customer_id
                               ORDER BY p.payment_date, p.payment_id) AS rn
    FROM    payment p
),

customer_first_movie AS (     -- movie rating of that very first rental
    SELECT  fp.customer_id,
            f.rating
    FROM    first_payment fp
    JOIN    rental     r ON r.rental_id    = fp.rental_id
    JOIN    inventory  i ON i.inventory_id = r.inventory_id
    JOIN    film       f ON f.film_id      = i.film_id
    WHERE   fp.rn = 1
),

customer_stats AS (           -- overall spend and rentals per customer
    SELECT  c.customer_id,
            SUM(p.amount)                         AS total_spent,
            COUNT(DISTINCT r.rental_id)           AS total_rentals
    FROM    customer  c
    JOIN    payment   p ON p.customer_id = c.customer_id
    JOIN    rental    r ON r.rental_id   = p.rental_id
    GROUP BY c.customer_id
),

combined AS (                 -- merge first‑movie rating with customer statistics
    SELECT  cf.rating,
            cs.total_spent,
            cs.total_rentals - 1                AS subsequent_rentals
    FROM    customer_first_movie cf
    JOIN    customer_stats       cs USING (customer_id)
)

SELECT  rating,
        ROUND(AVG(total_spent),        4) AS avg_total_amount_per_customer,
        ROUND(AVG(subsequent_rentals), 4) AS avg_subsequent_rentals
FROM    combined
GROUP BY rating
ORDER BY rating;