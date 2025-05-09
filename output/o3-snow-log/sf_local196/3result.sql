WITH first_payment AS (                                   -- earliest payment per customer
    SELECT
        p."customer_id",
        p."rental_id",
        ROW_NUMBER() OVER (PARTITION BY p."customer_id"
                           ORDER BY TO_TIMESTAMP_NTZ(p."payment_date") ASC,
                                    p."payment_id"       ASC) AS rn
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT" p
),

first_movie_rating AS (                                   -- rating of that first rental
    SELECT
        fp."customer_id",
        f."rating"
    FROM first_payment fp
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."RENTAL"   r ON r."rental_id"   = fp."rental_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."INVENTORY" i ON i."inventory_id" = r."inventory_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."FILM"      f ON f."film_id"      = i."film_id"
    WHERE fp.rn = 1
),

customer_stats AS (                                       -- totals per customer
    SELECT
        p."customer_id",
        SUM(p."amount")              AS total_amount,
        COUNT(DISTINCT p."rental_id") AS total_rentals
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT" p
    GROUP BY p."customer_id"
),

combined AS (                                             -- merge stats with first-movie rating
    SELECT
        fmr."rating",
        cs.total_amount,
        cs.total_rentals
    FROM customer_stats      cs
    JOIN first_movie_rating  fmr ON fmr."customer_id" = cs."customer_id"
)

SELECT
    "rating",
    AVG(total_amount)                   AS avg_total_amount_per_customer,
    AVG(total_rentals - 1)              AS avg_subsequent_rentals_per_customer
FROM combined
GROUP BY "rating"
ORDER BY "rating" NULLS LAST;