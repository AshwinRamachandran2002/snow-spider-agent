WITH first_payment AS (           -- earliest payment moment for every customer
    SELECT
        customer_id,
        MIN(payment_date) AS first_payment_date
    FROM payment
    GROUP BY customer_id
),
first_rental AS (                 -- pick (one of) the rentals that took place at that moment
    SELECT
        fp.customer_id,
        MIN(p.rental_id) AS first_rental_id   -- if several, take the one with smallest ID
    FROM first_payment fp
    JOIN payment p
      ON p.customer_id = fp.customer_id
     AND p.payment_date = fp.first_payment_date
    GROUP BY fp.customer_id
),
first_rating AS (                 -- rating of that very first movie
    SELECT
        fr.customer_id,
        f.rating
    FROM first_rental fr
    JOIN rental     r ON r.rental_id    = fr.first_rental_id
    JOIN inventory  i ON i.inventory_id = r.inventory_id
    JOIN film       f ON f.film_id      = i.film_id
),
customer_totals AS (              -- overall money spent by each customer
    SELECT
        customer_id,
        SUM(amount) AS total_amount
    FROM payment
    GROUP BY customer_id
),
customer_rentals AS (             -- how many rentals each customer has made
    SELECT
        customer_id,
        COUNT(*) AS total_rentals
    FROM rental
    GROUP BY customer_id
),
customer_stats AS (               -- merge everything, compute “subsequent rentals”
    SELECT
        fr.rating,
        ct.total_amount,
        (COALESCE(cr.total_rentals,1) - 1) AS subsequent_rentals   -- ensure non‑negative
    FROM first_rating       fr
    JOIN customer_totals    ct ON ct.customer_id = fr.customer_id
    LEFT JOIN customer_rentals cr ON cr.customer_id = fr.customer_id
)
SELECT
    rating,
    ROUND(AVG(total_amount),4)        AS avg_total_amount_per_customer,
    ROUND(AVG(subsequent_rentals),4)  AS avg_subsequent_rentals
FROM customer_stats
GROUP BY rating
ORDER BY rating;