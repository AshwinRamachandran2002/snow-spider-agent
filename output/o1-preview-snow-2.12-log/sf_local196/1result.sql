WITH
FirstRental AS (
    SELECT "customer_id", MIN("rental_date") AS "first_rental_date"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"
    GROUP BY "customer_id"
),
FirstRentalDetail AS (
    SELECT r."rental_id", r."customer_id", r."rental_date"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r
    JOIN FirstRental fr ON r."customer_id" = fr."customer_id" AND r."rental_date" = fr."first_rental_date"
),
FirstRentalChosen AS (
    SELECT "customer_id", MIN("rental_id") AS "first_rental_id"
    FROM FirstRentalDetail
    GROUP BY "customer_id"
),
FirstRentalRating AS (
    SELECT fr."customer_id", fr."first_rental_id", f."rating"
    FROM FirstRentalChosen fr
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r ON fr."first_rental_id" = r."rental_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY" inv ON r."inventory_id" = inv."inventory_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM" f ON inv."film_id" = f."film_id"
),
TotalSpend AS (
    SELECT "customer_id", SUM("amount") AS "total_spend"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY "customer_id"
),
SubsequentRentals AS (
    SELECT r."customer_id", COUNT(*) AS "subsequent_rentals"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r
    JOIN FirstRental fr ON r."customer_id" = fr."customer_id"
    WHERE r."rental_date" > fr."first_rental_date"
    GROUP BY r."customer_id"
),
CustomerMetrics AS (
    SELECT fr."customer_id", fr."rating", ts."total_spend", COALESCE(sr."subsequent_rentals", 0) AS "subsequent_rentals"
    FROM FirstRentalRating fr
    LEFT JOIN TotalSpend ts ON fr."customer_id" = ts."customer_id"
    LEFT JOIN SubsequentRentals sr ON fr."customer_id" = sr."customer_id"
)
SELECT "rating",
    ROUND(AVG("total_spend"), 4) AS "average_total_spend",
    ROUND(AVG("subsequent_rentals"), 4) AS "average_number_of_subsequent_rentals"
FROM CustomerMetrics
GROUP BY "rating"
ORDER BY "rating";