WITH first_payment AS (
    SELECT
        "customer_id",
        MIN("payment_date") AS "first_payment_date"
    FROM "payment"
    GROUP BY "customer_id"
),
first_rating AS (
    SELECT DISTINCT
        fp."customer_id",
        f."rating"
    FROM first_payment AS fp
    JOIN "payment"   AS p ON p."customer_id" = fp."customer_id"
                         AND p."payment_date" = fp."first_payment_date"
    JOIN "rental"    AS r ON r."rental_id"   = p."rental_id"
    JOIN "inventory" AS i ON i."inventory_id" = r."inventory_id"
    JOIN "film"      AS f ON f."film_id"      = i."film_id"
),
customer_stats AS (
    SELECT
        c."customer_id",
        COUNT(DISTINCT r."rental_id") AS "total_rentals",
        SUM(p."amount")               AS "total_amount"
    FROM "customer" AS c
    JOIN "rental"   AS r ON r."customer_id" = c."customer_id"
    JOIN "payment"  AS p ON p."rental_id"   = r."rental_id"
    GROUP BY c."customer_id"
)
SELECT
    fr."rating",
    ROUND(AVG(cs."total_amount"), 4)      AS "avg_total_spent_per_customer",
    ROUND(AVG(cs."total_rentals" - 1), 4) AS "avg_subsequent_rentals"
FROM first_rating   AS fr
JOIN customer_stats AS cs ON cs."customer_id" = fr."customer_id"
GROUP BY fr."rating"
ORDER BY fr."rating";