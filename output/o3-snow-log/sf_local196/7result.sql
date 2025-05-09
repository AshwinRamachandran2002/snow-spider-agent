WITH first_payment AS (     -- first payment (earliest payment date) made by each customer
    SELECT 
        p."customer_id",
        p."rental_id"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    QUALIFY ROW_NUMBER() OVER (PARTITION BY p."customer_id"
                               ORDER BY p."payment_date" ASC, p."payment_id" ASC) = 1
), 

first_movie AS (            -- rating of the movie associated with that first payment
    SELECT 
        fp."customer_id",
        f."rating"
    FROM first_payment fp
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL     r ON fp."rental_id"   = r."rental_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY  i ON r."inventory_id" = i."inventory_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM       f ON i."film_id"      = f."film_id"
), 

customer_total_amount AS (  -- total money spent by each customer
    SELECT 
        p."customer_id",
        SUM(p."amount") AS total_amount
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    GROUP BY p."customer_id"
), 

customer_total_rentals AS ( -- total number of rentals for each customer
    SELECT 
        r."customer_id",
        COUNT(*) AS total_rentals
    FROM SQLITE_SAKILA.SQLITE_SAKILA.RENTAL r
    GROUP BY r."customer_id"
), 

customer_stats AS (         -- combine stats per customer
    SELECT 
        fm."rating",
        cta.total_amount,
        CASE 
            WHEN ctr.total_rentals > 0 THEN ctr.total_rentals - 1
            ELSE 0
        END AS subsequent_rentals
    FROM first_movie fm
    LEFT JOIN customer_total_amount  cta ON fm."customer_id" = cta."customer_id"
    LEFT JOIN customer_total_rentals ctr ON fm."customer_id" = ctr."customer_id"
)

SELECT 
    "rating",
    AVG(total_amount)       AS avg_total_amount_per_customer,
    AVG(subsequent_rentals) AS avg_subsequent_rentals
FROM customer_stats
GROUP BY "rating"
ORDER BY "rating";