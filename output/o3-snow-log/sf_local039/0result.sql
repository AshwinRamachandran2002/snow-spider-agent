SELECT
    cat."name" AS "category_name",
    SUM(
        DATEDIFF(
            'second',
            TRY_TO_TIMESTAMP(ren."rental_date",  'YYYY-MM-DD HH24:MI:SS.FF3'),
            TRY_TO_TIMESTAMP(ren."return_date", 'YYYY-MM-DD HH24:MI:SS.FF3')
        ) / 3600.0
    ) AS "total_rental_hours"
FROM PAGILA.PAGILA.CITY          AS ci
JOIN PAGILA.PAGILA.ADDRESS       AS ad  ON ci."city_id"      = ad."city_id"
JOIN PAGILA.PAGILA.CUSTOMER      AS cu  ON ad."address_id"   = cu."address_id"
JOIN PAGILA.PAGILA.RENTAL        AS ren ON cu."customer_id"  = ren."customer_id"
JOIN PAGILA.PAGILA.INVENTORY     AS inv ON ren."inventory_id"= inv."inventory_id"
JOIN PAGILA.PAGILA.FILM_CATEGORY AS fc  ON inv."film_id"     = fc."film_id"
JOIN PAGILA.PAGILA.CATEGORY      AS cat ON fc."category_id"  = cat."category_id"
WHERE (ci."city" ILIKE 'A%' OR ci."city" LIKE '%-%')
  AND TRY_TO_TIMESTAMP(ren."rental_date",  'YYYY-MM-DD HH24:MI:SS.FF3') IS NOT NULL
  AND TRY_TO_TIMESTAMP(ren."return_date", 'YYYY-MM-DD HH24:MI:SS.FF3') IS NOT NULL
GROUP BY cat."name"
ORDER BY "total_rental_hours" DESC NULLS LAST
LIMIT 1;