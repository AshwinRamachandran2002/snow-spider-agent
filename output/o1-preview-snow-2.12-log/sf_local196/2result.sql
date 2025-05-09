WITH FirstRentals AS (
    SELECT R."customer_id", R."inventory_id"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.RENTAL R
    INNER JOIN (
        SELECT
            "customer_id",
            MIN("rental_date") AS "first_rental_date"
        FROM
            SQLITE_SAKILA.SQLITE_SAKILA.RENTAL
        GROUP BY
            "customer_id"
    ) FR ON R."customer_id" = FR."customer_id" AND R."rental_date" = FR."first_rental_date"
),
FirstRentalsWithRating AS (
    SELECT
        FR."customer_id",
        F."rating"
    FROM
        FirstRentals FR
    JOIN
        SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY I ON FR."inventory_id" = I."inventory_id"
    JOIN
        SQLITE_SAKILA.SQLITE_SAKILA.FILM F ON I."film_id" = F."film_id"
),
CustomerPayments AS (
    SELECT
        "customer_id",
        SUM("amount") AS "total_spent"
    FROM
        SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY
        "customer_id"
),
CustomerRentalCounts AS (
    SELECT
        "customer_id",
        COUNT(*) AS "total_rentals"
    FROM
        SQLITE_SAKILA.SQLITE_SAKILA.RENTAL
    GROUP BY
        "customer_id"
)
SELECT
    FRR."rating",
    ROUND(AVG(CP."total_spent"), 4) AS "average_total_spend",
    ROUND(AVG(CRC."total_rentals" - 1), 4) AS "average_number_of_subsequent_rentals"
FROM
    FirstRentalsWithRating FRR
JOIN
    CustomerPayments CP ON FRR."customer_id" = CP."customer_id"
JOIN
    CustomerRentalCounts CRC ON FRR."customer_id" = CRC."customer_id"
GROUP BY
    FRR."rating"
ORDER BY
    FRR."rating";