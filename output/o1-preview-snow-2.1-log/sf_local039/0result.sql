SELECT
    CATEGORY."name" AS "Category",
    ROUND(
        SUM(
            DATEDIFF(
                'second',
                TO_TIMESTAMP_NTZ(RENTAL."rental_date"),
                TO_TIMESTAMP_NTZ(RENTAL."return_date")
            ) / 3600.0
        ),
        4
    ) AS "total_rental_hours"
FROM
    PAGILA.PAGILA.RENTAL AS RENTAL
    JOIN PAGILA.PAGILA.CUSTOMER AS CUSTOMER
        ON RENTAL."customer_id" = CUSTOMER."customer_id"
    JOIN PAGILA.PAGILA.ADDRESS AS ADDRESS
        ON CUSTOMER."address_id" = ADDRESS."address_id"
    JOIN PAGILA.PAGILA.CITY AS CITY
        ON ADDRESS."city_id" = CITY."city_id"
    JOIN PAGILA.PAGILA.INVENTORY AS INVENTORY
        ON RENTAL."inventory_id" = INVENTORY."inventory_id"
    JOIN PAGILA.PAGILA.FILM_CATEGORY AS FILM_CATEGORY
        ON INVENTORY."film_id" = FILM_CATEGORY."film_id"
    JOIN PAGILA.PAGILA.CATEGORY AS CATEGORY
        ON FILM_CATEGORY."category_id" = CATEGORY."category_id"
WHERE
    (CITY."city" ILIKE 'A%' OR CITY."city" ILIKE '%-%')
    AND RENTAL."rental_date" IS NOT NULL
    AND RENTAL."return_date" IS NOT NULL
    AND RENTAL."rental_date" != ''
    AND RENTAL."return_date" != ''
GROUP BY
    CATEGORY."name"
ORDER BY
    "total_rental_hours" DESC NULLS LAST
LIMIT 1;