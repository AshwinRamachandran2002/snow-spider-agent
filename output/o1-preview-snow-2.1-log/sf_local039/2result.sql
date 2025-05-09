WITH customers_in_cities AS (
  SELECT c."customer_id"
  FROM PAGILA.PAGILA.CUSTOMER c
  JOIN PAGILA.PAGILA.ADDRESS a ON c."address_id" = a."address_id"
  JOIN PAGILA.PAGILA.CITY ci ON a."city_id" = ci."city_id"
  WHERE ci."city" ILIKE 'A%' OR ci."city" LIKE '%-%'
),
rentals_by_customers AS (
  SELECT r.*
  FROM PAGILA.PAGILA.RENTAL r
  JOIN customers_in_cities c ON r."customer_id" = c."customer_id"
  WHERE r."return_date" IS NOT NULL AND r."return_date" != '' AND r."rental_date" IS NOT NULL AND r."rental_date" != ''
),
rentals_with_duration AS (
  SELECT 
    r."rental_id",
    r."customer_id",
    r."inventory_id",
    TRY_TO_TIMESTAMP(r."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF') AS "rental_date_ts",
    TRY_TO_TIMESTAMP(r."return_date", 'YYYY-MM-DD HH24:MI:SS.FF') AS "return_date_ts"
  FROM rentals_by_customers r
),
valid_rentals AS (
  SELECT 
    r."rental_id",
    r."customer_id",
    r."inventory_id",
    TIMESTAMPDIFF('second', r."rental_date_ts", r."return_date_ts") / 3600.0 AS "rental_hours"
  FROM rentals_with_duration r
  WHERE r."rental_date_ts" IS NOT NULL AND r."return_date_ts" IS NOT NULL AND r."rental_date_ts" <= r."return_date_ts"
),
rentals_with_film AS (
  SELECT 
    r.*, 
    i."film_id"
  FROM valid_rentals r
  JOIN PAGILA.PAGILA.INVENTORY i ON r."inventory_id" = i."inventory_id"
),
rentals_with_category AS (
  SELECT 
    r.*, 
    fc."category_id", 
    c."name" AS "category_name"
  FROM rentals_with_film r
  JOIN PAGILA.PAGILA.FILM_CATEGORY fc ON r."film_id" = fc."film_id"
  JOIN PAGILA.PAGILA.CATEGORY c ON fc."category_id" = c."category_id"
)
SELECT 
  rwc."category_name" AS "Category",
  ROUND(SUM(rwc."rental_hours"), 4) AS "total_rental_hours"
FROM rentals_with_category rwc
GROUP BY rwc."category_name"
ORDER BY "total_rental_hours" DESC NULLS LAST
LIMIT 1;