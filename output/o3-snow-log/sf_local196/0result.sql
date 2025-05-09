WITH first_payment AS (      -- earliest payment (i.e., first rental) per customer
    SELECT
        "customer_id",
        "rental_id",
        ROW_NUMBER() OVER (
            PARTITION BY "customer_id"
            ORDER BY TO_TIMESTAMP("payment_date") ASC
        ) AS rn
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
), 

first_rental AS (            -- keep only the very first rental for every customer
    SELECT
        "customer_id",
        "rental_id"
    FROM first_payment
    WHERE rn = 1
), 

first_film AS (              -- rating of the film in that first rental
    SELECT
        fr."customer_id",
        f."rating"
    FROM first_rental              fr
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL     r ON r."rental_id"   = fr."rental_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY  i ON i."inventory_id" = r."inventory_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM       f ON f."film_id"      = i."film_id"
), 

customer_metrics AS (        -- total spend and total rentals for every customer
    SELECT
        "customer_id",
        SUM("amount")                 AS total_amount,
        COUNT(DISTINCT "rental_id")   AS total_rentals
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id"
), 

combined AS (                -- combine first-film rating with customer metrics
    SELECT
        ff."rating",
        cm.total_amount,
        cm.total_rentals - 1 AS subsequent_rentals    -- rentals after the first one
    FROM first_film       ff
    JOIN customer_metrics cm ON cm."customer_id" = ff."customer_id"
)

SELECT
    "rating",
    AVG(total_amount)       AS avg_total_amount_per_customer,
    AVG(subsequent_rentals) AS avg_subsequent_rentals
FROM combined
GROUP BY "rating"
ORDER BY "rating";