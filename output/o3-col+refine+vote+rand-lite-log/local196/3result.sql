WITH first_movie AS (
    SELECT
        p."customer_id",
        f."rating",
        ROW_NUMBER() OVER (
            PARTITION BY p."customer_id"
            ORDER BY p."payment_date"
        ) AS rn
    FROM "payment"   AS p
    JOIN "rental"    AS r ON r."rental_id"   = p."rental_id"
    JOIN "inventory" AS i ON i."inventory_id" = r."inventory_id"
    JOIN "film"      AS f ON f."film_id"      = i."film_id"
),
first_per_customer AS (
    SELECT
        "customer_id",
        "rating"
    FROM first_movie
    WHERE rn = 1
),
customer_totals AS (
    SELECT
        p."customer_id",
        SUM(p."amount")               AS total_spent,
        COUNT(DISTINCT p."rental_id") AS total_rentals
    FROM "payment" AS p
    GROUP BY p."customer_id"
)
SELECT
    fpc."rating"                                    AS first_movie_rating,
    ROUND(AVG(ct.total_spent), 4)                   AS avg_total_spent_per_customer,
    ROUND(AVG(ct.total_rentals - 1), 4)             AS avg_subsequent_rentals
FROM first_per_customer AS fpc
JOIN customer_totals   AS ct USING ("customer_id")
GROUP BY fpc."rating"
ORDER BY fpc."rating";