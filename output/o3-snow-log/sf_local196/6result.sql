WITH first_movie AS (   -- rating of the very first paid rental per customer
    SELECT
        p."customer_id",
        f."rating",
        ROW_NUMBER() OVER (PARTITION BY p."customer_id" ORDER BY p."payment_date") AS rn
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"  p
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"   r ON p."rental_id"    = r."rental_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY" i ON r."inventory_id" = i."inventory_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM"      f ON i."film_id"      = f."film_id"
), 
customer_totals AS (    -- overall spend and number of rentals per customer
    SELECT
        "customer_id",
        SUM("amount")                 AS total_amount,
        COUNT(DISTINCT "rental_id")   AS total_rentals
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY "customer_id"
), 
customer_info AS (      -- keep only customers’ first-movie rating with their totals
    SELECT
        ct."customer_id",
        fm."rating",
        ct.total_amount,
        (ct.total_rentals - 1) AS subsequent_rentals
    FROM customer_totals ct
    JOIN first_movie fm
      ON ct."customer_id" = fm."customer_id"
    WHERE fm.rn = 1      -- first (earliest) payment per customer
)
SELECT
    "rating",
    AVG(total_amount)       AS avg_total_amount_spent_per_customer,
    AVG(subsequent_rentals) AS avg_number_of_subsequent_rentals
FROM customer_info
GROUP BY "rating"
ORDER BY "rating";