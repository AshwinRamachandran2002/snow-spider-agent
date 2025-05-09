WITH first_payments AS (               -- 1. choose the earliest payment per customer
    SELECT
        p.customer_id,
        p.rental_id,
        ROW_NUMBER() OVER (
            PARTITION BY p.customer_id
            ORDER BY p.payment_date, p.payment_id           -- tie‑breaker
        ) AS rn
    FROM payment AS p
),

first_movie AS (                       -- 2. movie (and its rating) of that first payment
    SELECT
        fp.customer_id,
        f.rating
    FROM first_payments fp
    JOIN rental    r ON r.rental_id    = fp.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film      f ON f.film_id      = i.film_id
    WHERE fp.rn = 1
),

customer_totals AS (                   -- 3. overall spending and rental count per customer
    SELECT
        customer_id,
        SUM(amount)               AS total_amount,
        COUNT(DISTINCT rental_id) AS total_rentals
    FROM payment
    GROUP BY customer_id
),

customer_stats AS (                    -- 4. combine the two per customer result sets
    SELECT
        fm.rating,
        ct.total_amount,
        ct.total_rentals - 1 AS subsequent_rentals
    FROM first_movie     fm
    JOIN customer_totals ct USING (customer_id)
)

-- 5. final aggregation by first‑movie rating
SELECT
    rating,
    AVG(total_amount)       AS avg_total_amount_per_customer,
    AVG(subsequent_rentals) AS avg_subsequent_rentals
FROM customer_stats
GROUP BY rating
ORDER BY rating;