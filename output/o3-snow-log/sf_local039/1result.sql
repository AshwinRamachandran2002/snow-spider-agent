WITH RENTAL_HOURS AS (
    SELECT
        C."name" AS "category_name",
        DATEDIFF(
            'second',
            TRY_TO_TIMESTAMP(R."rental_date"),
            TRY_TO_TIMESTAMP(R."return_date")
        ) / 3600.0 AS "rental_hours"
    FROM PAGILA.PAGILA.RENTAL         R
    JOIN PAGILA.PAGILA.INVENTORY      I  ON R."inventory_id" = I."inventory_id"
    JOIN PAGILA.PAGILA.FILM_CATEGORY  FC ON I."film_id"      = FC."film_id"
    JOIN PAGILA.PAGILA.CATEGORY       C  ON FC."category_id" = C."category_id"
    JOIN PAGILA.PAGILA.CUSTOMER       CU ON R."customer_id"  = CU."customer_id"
    JOIN PAGILA.PAGILA.ADDRESS        A  ON CU."address_id"  = A."address_id"
    JOIN PAGILA.PAGILA.CITY           CI ON A."city_id"      = CI."city_id"
    WHERE (CI."city" ILIKE 'A%' OR CI."city" ILIKE '%-%')      -- cities starting with A or containing a hyphen
      AND TRY_TO_TIMESTAMP(R."rental_date")  IS NOT NULL       -- exclude invalid timestamps
      AND TRY_TO_TIMESTAMP(R."return_date") IS NOT NULL
)

SELECT
    "category_name",
    SUM("rental_hours") AS "total_rental_hours"
FROM RENTAL_HOURS
GROUP BY "category_name"
ORDER BY "total_rental_hours" DESC NULLS LAST
LIMIT 1;