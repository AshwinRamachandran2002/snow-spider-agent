WITH rental_hours AS (
    SELECT
        cat."name" AS "category_name",
        ROUND(
            SUM(
                DATEDIFF(
                    'minute',
                    TRY_TO_TIMESTAMP(r."rental_date"),
                    TRY_TO_TIMESTAMP(r."return_date")
                )
            ) / 60.0,
            4
        ) AS "total_rental_hours"
    FROM PAGILA.PAGILA.CITY          c
    JOIN PAGILA.PAGILA.ADDRESS       a  ON c."city_id"      = a."city_id"
    JOIN PAGILA.PAGILA.CUSTOMER      cu ON a."address_id"   = cu."address_id"
    JOIN PAGILA.PAGILA.RENTAL        r  ON cu."customer_id" = r."customer_id"
    JOIN PAGILA.PAGILA.INVENTORY     i  ON r."inventory_id" = i."inventory_id"
    JOIN PAGILA.PAGILA.FILM_CATEGORY fc ON i."film_id"      = fc."film_id"
    JOIN PAGILA.PAGILA.CATEGORY      cat ON fc."category_id"= cat."category_id"
    WHERE r."return_date" IS NOT NULL
      AND r."return_date" <> ''
      AND r."rental_date"  <> ''
      AND (c."city" ILIKE 'A%' OR c."city" LIKE '%-%')
    GROUP BY cat."name"
)
SELECT  "category_name",
        "total_rental_hours"
FROM    rental_hours
ORDER BY "total_rental_hours" DESC NULLS LAST
LIMIT 1;