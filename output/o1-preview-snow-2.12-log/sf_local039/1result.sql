SELECT
    c."name" AS category_name,
    ROUND(SUM(DATEDIFF('minute', TRY_TO_TIMESTAMP(r."rental_date"), TRY_TO_TIMESTAMP(r."return_date")))/60.0, 4) AS total_hours
FROM
    PAGILA.PAGILA.RENTAL r
    JOIN PAGILA.PAGILA.CUSTOMER cu ON r."customer_id" = cu."customer_id"
    JOIN PAGILA.PAGILA.ADDRESS a ON cu."address_id" = a."address_id"
    JOIN PAGILA.PAGILA.CITY ci ON a."city_id" = ci."city_id"
    JOIN PAGILA.PAGILA.INVENTORY i ON r."inventory_id" = i."inventory_id"
    JOIN PAGILA.PAGILA.FILM_CATEGORY fc ON i."film_id" = fc."film_id"
    JOIN PAGILA.PAGILA.CATEGORY c ON fc."category_id" = c."category_id"
WHERE
    (ci."city" ILIKE 'A%' OR ci."city" LIKE '%-%')
    AND r."return_date" IS NOT NULL
GROUP BY
    c."name"
ORDER BY
    total_hours DESC NULLS LAST
LIMIT 1;