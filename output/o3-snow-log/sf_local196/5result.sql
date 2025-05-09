WITH first_payment AS (                -- earliest payment (i.e. first rental) per customer
    SELECT  p."customer_id",
            p."rental_id",
            ROW_NUMBER() OVER (PARTITION BY p."customer_id"
                               ORDER BY p."payment_date", p."payment_id") AS rn
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
),
first_movie AS (                       -- rating of the first-rented movie for each customer
    SELECT  fp."customer_id",
            f."rating"        AS first_rating
    FROM    first_payment fp
            JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL    r ON fp."rental_id"   = r."rental_id"
            JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY i ON r."inventory_id" = i."inventory_id"
            JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM      f ON i."film_id"      = f."film_id"
    WHERE   fp.rn = 1
),
customer_stats AS (                     -- total spend and total rentals per customer
    SELECT  p."customer_id",
            SUM(p."amount")                         AS total_amount,
            COUNT(DISTINCT p."rental_id")           AS total_rentals
    FROM    SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    GROUP BY p."customer_id"
)
SELECT  fm.first_rating                                 AS "RATING",
        CAST(AVG(cs.total_amount)        AS NUMBER(38,4)) AS "AVG_TOTAL_AMOUNT",
        CAST(AVG(cs.total_rentals - 1)   AS NUMBER(38,4)) AS "AVG_SUBSEQUENT_RENTALS"
FROM    first_movie   fm
        JOIN customer_stats cs ON fm."customer_id" = cs."customer_id"
GROUP BY fm.first_rating
ORDER BY fm.first_rating;