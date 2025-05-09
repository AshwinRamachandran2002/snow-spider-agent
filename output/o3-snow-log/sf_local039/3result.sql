WITH "target_cities" AS (
    SELECT "city_id"
    FROM PAGILA.PAGILA.CITY
    WHERE UPPER("city") LIKE 'A%'      -- starts with “A”
       OR "city" LIKE '%-%'            -- contains a hyphen
),
"rentals_in_target" AS (
    SELECT
        r."inventory_id",
        TRY_TO_TIMESTAMP(r."rental_date")  AS "rental_ts",
        TRY_TO_TIMESTAMP(r."return_date")  AS "return_ts"
    FROM PAGILA.PAGILA.RENTAL   r
    JOIN PAGILA.PAGILA.CUSTOMER c  ON r."customer_id" = c."customer_id"
    JOIN PAGILA.PAGILA.ADDRESS  a  ON c."address_id"  = a."address_id"
    JOIN "target_cities"        tc ON a."city_id"     = tc."city_id"
    WHERE r."return_date" IS NOT NULL
      AND TRY_TO_TIMESTAMP(r."rental_date") IS NOT NULL
      AND TRY_TO_TIMESTAMP(r."return_date") IS NOT NULL
),
"category_hours" AS (
    SELECT
        fc."category_id",
        SUM(DATEDIFF('second', rit."rental_ts", rit."return_ts")::FLOAT / 3600.0) AS "total_hours"
    FROM "rentals_in_target"       rit
    JOIN PAGILA.PAGILA.INVENTORY   i  ON rit."inventory_id" = i."inventory_id"
    JOIN PAGILA.PAGILA.FILM_CATEGORY fc ON i."film_id"      = fc."film_id"
    GROUP BY fc."category_id"
)
SELECT
    cat."name"  AS "film_category",
    ch."total_hours"
FROM "category_hours" ch
JOIN PAGILA.PAGILA.CATEGORY cat ON ch."category_id" = cat."category_id"
ORDER BY ch."total_hours" DESC NULLS LAST
LIMIT 1;