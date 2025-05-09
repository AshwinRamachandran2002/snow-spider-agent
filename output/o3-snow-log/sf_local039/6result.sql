SELECT
    cat."name"                                       AS "category_name",
    SUM(
        DATEDIFF(
            'second',
            TRY_TO_TIMESTAMP(r."rental_date"),
            TRY_TO_TIMESTAMP(r."return_date")
        ) / 3600.0
    )                                                AS "total_rental_hours"
FROM PAGILA.PAGILA.RENTAL         r
JOIN PAGILA.PAGILA.CUSTOMER       cu  ON r."customer_id"  = cu."customer_id"
JOIN PAGILA.PAGILA.ADDRESS        a   ON cu."address_id"  = a."address_id"
JOIN PAGILA.PAGILA.CITY           ci  ON a."city_id"      = ci."city_id"
JOIN PAGILA.PAGILA.INVENTORY      i   ON r."inventory_id" = i."inventory_id"
JOIN PAGILA.PAGILA.FILM_CATEGORY  fc  ON i."film_id"      = fc."film_id"
JOIN PAGILA.PAGILA.CATEGORY       cat ON fc."category_id" = cat."category_id"
WHERE (ci."city" ILIKE 'A%' OR ci."city" LIKE '%-%')     -- city starts with 'A' or contains hyphen
  AND TRY_TO_TIMESTAMP(r."rental_date")  IS NOT NULL
  AND TRY_TO_TIMESTAMP(r."return_date")  IS NOT NULL
GROUP BY cat."name"
ORDER BY "total_rental_hours" DESC NULLS LAST
LIMIT 1;