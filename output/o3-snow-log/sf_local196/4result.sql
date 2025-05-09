WITH first_payment AS (   /* 1. locate the first (earliest) payment for every customer */
    SELECT
        p."customer_id",
        p."rental_id",
        ROW_NUMBER() OVER (PARTITION BY p."customer_id" 
                           ORDER BY p."payment_date") AS rn
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
),

customer_first_rating AS (   /* 2. get the rating of the film tied to that first rental */
    SELECT
        fp."customer_id",
        f."rating"
    FROM first_payment fp
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL     r ON fp."rental_id"  = r."rental_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY  i ON r."inventory_id" = i."inventory_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM       f ON i."film_id"      = f."film_id"
    WHERE fp.rn = 1
),

customer_totals AS (   /* 3. total spend & total rentals for each customer */
    SELECT
        p."customer_id",
        SUM(p."amount")                 AS total_spent,
        COUNT(DISTINCT p."rental_id")   AS total_rentals
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    GROUP BY p."customer_id"
),

customer_summary AS (   /* 4. merge the above pieces & compute “subsequent rentals” */
    SELECT
        ct."customer_id",
        cfr."rating",
        ct.total_spent,
        (ct.total_rentals - 1)          AS subsequent_rentals
    FROM customer_totals       ct
    JOIN customer_first_rating cfr ON ct."customer_id" = cfr."customer_id"
)

/* 5. final aggregation by first-movie rating */
SELECT
    cs."rating",
    AVG(cs.total_spent)        AS avg_total_amount_spent_per_customer,
    AVG(cs.subsequent_rentals) AS avg_subsequent_rentals
FROM customer_summary cs
GROUP BY cs."rating"
ORDER BY cs."rating";