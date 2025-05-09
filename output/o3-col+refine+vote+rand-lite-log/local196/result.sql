WITH first_movie AS (
    /* Rating of each customer's very first rented movie */
    SELECT fp."customer_id",
           f."rating"
    FROM (
        SELECT "customer_id",
               MIN("payment_date") AS "first_payment_date"
        FROM   "payment"
        GROUP  BY "customer_id"
    ) AS fp
    JOIN "payment"   AS p ON p."customer_id" = fp."customer_id"
                         AND p."payment_date" = fp."first_payment_date"
    JOIN "rental"    AS r ON r."rental_id"    = p."rental_id"
    JOIN "inventory" AS i ON i."inventory_id" = r."inventory_id"
    JOIN "film"      AS f ON f."film_id"      = i."film_id"
),
cust_totals AS (
    /* Total money spent and total rentals per customer */
    SELECT "customer_id",
           SUM("amount")               AS "total_spent",
           COUNT(DISTINCT "rental_id") AS "total_rentals"
    FROM   "payment"
    GROUP  BY "customer_id"
)
SELECT fm."rating",
       AVG(ct."total_spent")        AS "avg_total_spent_per_customer",
       AVG(ct."total_rentals" - 1)  AS "avg_subsequent_rentals"
FROM   first_movie AS fm
JOIN   cust_totals AS ct
       ON ct."customer_id" = fm."customer_id"
GROUP  BY fm."rating";