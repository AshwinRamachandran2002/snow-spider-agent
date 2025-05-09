WITH city_filter AS (      -- Cities whose name starts with 'A' or contains a hyphen
    SELECT "city_id"
    FROM PAGILA.PAGILA.CITY
    WHERE "city" ILIKE 'A%'           -- starts with A (case-insensitive)
       OR "city" LIKE '%-%'           -- contains a hyphen
),
customers_in_city AS (     -- Customers living in those cities
    SELECT cu."customer_id"
    FROM PAGILA.PAGILA.CUSTOMER  cu
    JOIN PAGILA.PAGILA.ADDRESS   ad ON cu."address_id" = ad."address_id"
    WHERE ad."city_id" IN (SELECT "city_id" FROM city_filter)
),
rental_details AS (        -- Rental hours (after safely parsing timestamps)
    SELECT r."rental_id",
           r."inventory_id",
           DATEDIFF(
               'hour',
               TRY_TO_TIMESTAMP(r."rental_date"),
               TRY_TO_TIMESTAMP(r."return_date")
           ) AS rental_hours
    FROM PAGILA.PAGILA.RENTAL r
    WHERE r."customer_id" IN (SELECT "customer_id" FROM customers_in_city)
      AND TRY_TO_TIMESTAMP(r."rental_date")  IS NOT NULL
      AND TRY_TO_TIMESTAMP(r."return_date") IS NOT NULL
),
film_category_hours AS (   -- Sum of rental hours per film category
    SELECT fc."category_id",
           SUM(rd.rental_hours) AS total_hours
    FROM rental_details             rd
    JOIN PAGILA.PAGILA.INVENTORY    i  ON rd."inventory_id" = i."inventory_id"
    JOIN PAGILA.PAGILA.FILM_CATEGORY fc ON i."film_id" = fc."film_id"
    GROUP BY fc."category_id"
)
SELECT c."name"        AS category_name,
       fch.total_hours AS total_rental_hours
FROM film_category_hours fch
JOIN PAGILA.PAGILA.CATEGORY c
  ON fch."category_id" = c."category_id"
ORDER BY fch.total_hours DESC NULLS LAST
LIMIT 1;