WITH first_rental_per_customer AS (
  SELECT r."customer_id", r."rental_id", r."rental_date", r."inventory_id",
    ROW_NUMBER() OVER (PARTITION BY r."customer_id" ORDER BY r."rental_date", r."rental_id") AS rn
  FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r
),
customer_first_ratings AS (
  SELECT fr."customer_id", f."rating"
  FROM first_rental_per_customer fr
  JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY" i ON fr."inventory_id" = i."inventory_id"
  JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM" f ON i."film_id" = f."film_id"
  WHERE fr.rn = 1
),
customer_total_spent AS (
  SELECT p."customer_id", SUM(p."amount") AS total_spent
  FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
  GROUP BY p."customer_id"
),
customer_total_rentals AS (
  SELECT r."customer_id", COUNT(*) AS total_rentals
  FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r
  GROUP BY r."customer_id"
),
customer_data AS (
  SELECT cfr."customer_id", cfr."rating", cts.total_spent, (ctr.total_rentals - 1) AS subsequent_rentals
  FROM customer_first_ratings cfr
  JOIN customer_total_spent cts ON cfr."customer_id" = cts."customer_id"
  JOIN customer_total_rentals ctr ON cfr."customer_id" = ctr."customer_id"
)
SELECT
  "rating",
  ROUND(AVG(total_spent), 4) AS "average_total_spent",
  ROUND(AVG(subsequent_rentals), 4) AS "average_number_of_subsequent_rentals"
FROM customer_data
GROUP BY "rating"
ORDER BY "rating";