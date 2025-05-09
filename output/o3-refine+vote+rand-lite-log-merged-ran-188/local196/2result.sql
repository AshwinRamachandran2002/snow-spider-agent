WITH first_pay AS (               -- earliest payment per customer
    SELECT
        customer_id,
        MIN(payment_date) AS first_pay_date
    FROM payment
    GROUP BY customer_id
),
first_pay_row AS (                -- keep one concrete payment row (smallest id) for that date
    SELECT
        p.customer_id,
        MIN(p.payment_id) AS first_payment_id
    FROM payment p
    JOIN first_pay fp
      ON fp.customer_id = p.customer_id
     AND fp.first_pay_date = p.payment_date
    GROUP BY p.customer_id
),
first_movie_rating AS (           -- rating of the very first film rented by each customer
    SELECT
        fpr.customer_id,
        f.rating
    FROM first_pay_row  fpr
    JOIN payment    p ON p.payment_id   = fpr.first_payment_id
    JOIN rental     r ON r.rental_id    = p.rental_id
    JOIN inventory  i ON i.inventory_id = r.inventory_id
    JOIN film       f ON f.film_id      = i.film_id
),
customer_spent AS (               -- total money spent by each customer
    SELECT
        customer_id,
        SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
),
customer_rentals AS (             -- total rentals per customer
    SELECT
        customer_id,
        COUNT(*) AS total_rentals
    FROM rental
    GROUP BY customer_id
),
customer_metrics AS (             -- merge all customer–level facts
    SELECT
        fmr.rating,
        fmr.customer_id,
        cs.total_spent,
        cr.total_rentals
    FROM first_movie_rating fmr
    LEFT JOIN customer_spent   cs ON cs.customer_id = fmr.customer_id
    LEFT JOIN customer_rentals cr ON cr.customer_id = fmr.customer_id
)
SELECT
    rating,
    ROUND(AVG(total_spent),4)                      AS avg_total_amount_spent,
    ROUND(AVG(COALESCE(total_rentals,1) - 1),4)    AS avg_subsequent_rentals
FROM customer_metrics
GROUP BY rating
ORDER BY rating;