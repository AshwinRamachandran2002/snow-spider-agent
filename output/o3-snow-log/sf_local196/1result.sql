WITH first_payment AS (                       -- earliest payment per customer
    SELECT
        "customer_id",
        "rental_id",
        "payment_date"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    QUALIFY ROW_NUMBER() OVER (
               PARTITION BY "customer_id"
               ORDER BY "payment_date" ASC, "payment_id" ASC
           ) = 1
),
first_movie AS (                              -- rating of that very first rental
    SELECT
        fp."customer_id",
        f."rating"
    FROM first_payment fp
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL     r ON r."rental_id"    = fp."rental_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY  i ON i."inventory_id" = r."inventory_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM       f ON f."film_id"      = i."film_id"
),
customer_totals AS (                          -- total spend & rentals per customer
    SELECT
        c."customer_id",
        SUM(p."amount")                 AS total_amount,
        COUNT(DISTINCT r."rental_id")   AS total_rentals
    FROM SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER c
    LEFT JOIN SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
           ON p."customer_id" = c."customer_id"
    LEFT JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL  r
           ON r."customer_id" = c."customer_id"
    GROUP BY c."customer_id"
)
SELECT
    fm."rating",
    ROUND(AVG(ct.total_amount), 4)                                                AS "avg_total_amount_per_customer",
    ROUND(AVG(CASE WHEN ct.total_rentals > 0 THEN ct.total_rentals - 1 ELSE 0 END), 4)
                                                                                 AS "avg_subsequent_rentals"
FROM first_movie      fm
JOIN customer_totals  ct ON ct."customer_id" = fm."customer_id"
GROUP BY fm."rating"
ORDER BY fm."rating" NULLS LAST;