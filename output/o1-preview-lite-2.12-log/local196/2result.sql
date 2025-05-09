WITH first_rentals AS (
    SELECT
        r."customer_id",
        r."rental_id",
        r."rental_date",
        i."film_id",
        f."rating",
        ROW_NUMBER() OVER (PARTITION BY r."customer_id" ORDER BY r."rental_date", r."rental_id") AS rn
    FROM "rental" r
    JOIN "inventory" i ON r."inventory_id" = i."inventory_id"
    JOIN "film" f ON i."film_id" = f."film_id"
),
first_rental_per_customer AS (
    SELECT
        "customer_id",
        "rental_date" AS "first_rental_date",
        "rating"
    FROM first_rentals
    WHERE rn = 1
),
subsequent_rentals AS (
    SELECT
        r."customer_id",
        COUNT(*) AS "subsequent_rentals"
    FROM "rental" r
    JOIN first_rental_per_customer fr ON r."customer_id" = fr."customer_id"
    WHERE r."rental_date" > fr."first_rental_date"
    GROUP BY r."customer_id"
),
total_spend AS (
    SELECT
        "customer_id",
        SUM("amount") AS "total_spent"
    FROM "payment"
    GROUP BY "customer_id"
)
SELECT
    fr."rating" AS "Rating",
    ROUND(AVG(ts."total_spent"), 4) AS "Average_Total_Spend",
    ROUND(AVG(sr."subsequent_rentals"), 4) AS "Average_Number_of_Subsequent_Rentals"
FROM first_rental_per_customer fr
LEFT JOIN subsequent_rentals sr ON fr."customer_id" = sr."customer_id"
LEFT JOIN total_spend ts ON fr."customer_id" = ts."customer_id"
GROUP BY fr."rating";