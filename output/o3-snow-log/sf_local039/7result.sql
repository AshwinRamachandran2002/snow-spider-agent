SELECT
    cat."name" AS "category_name",
    SUM(
        DATEDIFF(
            'second',
            TRY_TO_TIMESTAMP(r."rental_date"),
            TRY_TO_TIMESTAMP(r."return_date")
        )
    ) / 3600.0 AS "total_rental_hours"
FROM PAGILA.PAGILA.RENTAL        r
JOIN PAGILA.PAGILA.CUSTOMER      cu ON cu."customer_id" = r."customer_id"
JOIN PAGILA.PAGILA.ADDRESS       a  ON a."address_id"   = cu."address_id"
JOIN PAGILA.PAGILA.CITY          c  ON c."city_id"      = a."city_id"
JOIN PAGILA.PAGILA.INVENTORY     i  ON i."inventory_id" = r."inventory_id"
JOIN PAGILA.PAGILA.FILM_CATEGORY fc ON fc."film_id"     = i."film_id"
JOIN PAGILA.PAGILA.CATEGORY      cat ON cat."category_id" = fc."category_id"
WHERE TRY_TO_TIMESTAMP(r."rental_date")  IS NOT NULL
  AND TRY_TO_TIMESTAMP(r."return_date") IS NOT NULL
  AND (c."city" ILIKE 'A%' OR c."city" LIKE '%-%')
GROUP BY cat."name"
ORDER BY "total_rental_hours" DESC NULLS LAST
LIMIT 1;