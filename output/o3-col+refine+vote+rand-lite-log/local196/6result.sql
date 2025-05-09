WITH first_movie AS (
    /* first rented movie (by earliest payment) and its rating per customer */
    SELECT
        p."customer_id",
        f."rating",
        ROW_NUMBER() OVER (PARTITION BY p."customer_id"
                           ORDER BY p."payment_date") AS rn
    FROM   "payment"   AS p
    JOIN   "rental"    AS r ON r."rental_id"    = p."rental_id"
    JOIN   "inventory" AS i ON i."inventory_id" = r."inventory_id"
    JOIN   "film"      AS f ON f."film_id"      = i."film_id"
),
customer_totals AS (
    /* overall spend and rental count per customer */
    SELECT
        "customer_id",
        SUM("amount") AS total_spent,
        COUNT(*)      AS total_rentals
    FROM "payment"
    GROUP BY "customer_id"
)
SELECT
    fm."rating"                                         AS first_movie_rating,
    ROUND(AVG(ct.total_spent), 4)                       AS avg_total_spent_per_customer,
    ROUND(AVG(ct.total_rentals - 1), 4)                 AS avg_subsequent_rentals
FROM       first_movie      AS fm
JOIN       customer_totals  AS ct
       ON  ct."customer_id" = fm."customer_id"
WHERE      fm.rn = 1               -- keep only the first movie per customer
GROUP BY   fm."rating";