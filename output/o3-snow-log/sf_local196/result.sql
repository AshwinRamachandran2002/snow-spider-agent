/* 1) Identify the first rental (by the earliest payment_date) for every customer
   2) Get the rating of that first rented film
   3) Compute, for every customer, total amount spent and total rentals made
   4) For each rating category of the first film, return:
        • average total amount spent per customer
        • average number of subsequent rentals (total rentals – 1)
*/
WITH first_payment_per_customer AS (          -- earliest payment_date
    SELECT
        p."customer_id",
        MIN(p."payment_date") AS first_payment_date
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT" p
    GROUP BY p."customer_id"
),
first_payment_row AS (                         -- keep the row(s) on that date
    SELECT
        p."customer_id",
        p."rental_id",
        p."payment_id",
        ROW_NUMBER() OVER (PARTITION BY p."customer_id" ORDER BY p."payment_id") AS rn
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT" p
    JOIN first_payment_per_customer fp
      ON p."customer_id" = fp."customer_id"
     AND p."payment_date" = fp.first_payment_date
),
first_rental AS (                              -- one row per customer
    SELECT
        "customer_id",
        "rental_id"
    FROM first_payment_row
    WHERE rn = 1
),
first_movie_rating AS (                        -- rating of that first film
    SELECT
        fr."customer_id",
        f."rating" AS first_rating
    FROM first_rental fr
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."RENTAL"     r ON r."rental_id"   = fr."rental_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."INVENTORY"  i ON i."inventory_id" = r."inventory_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."FILM"       f ON f."film_id"      = i."film_id"
),
customer_totals AS (                           -- total spend & rentals per customer
    SELECT
        p."customer_id",
        SUM(p."amount")                          AS total_amount,
        COUNT(DISTINCT p."rental_id")            AS total_rentals
    FROM SQLITE_SAKILA.SQLITE_SAKILA."PAYMENT" p
    GROUP BY p."customer_id"
),
combined AS (
    SELECT
        fm.first_rating,
        ct.total_amount,
        (ct.total_rentals - 1) AS subsequent_rentals
    FROM first_movie_rating fm
    JOIN customer_totals    ct ON fm."customer_id" = ct."customer_id"
)
SELECT
    first_rating                                              AS "rating",
    ROUND(AVG(total_amount),      4)                          AS "avg_total_amount_per_customer",
    ROUND(AVG(subsequent_rentals),4)                          AS "avg_subsequent_rentals"
FROM combined
GROUP BY first_rating
ORDER BY first_rating NULLS LAST;