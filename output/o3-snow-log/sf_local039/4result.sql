WITH "cte_cities" AS (
    SELECT "city_id"
    FROM PAGILA.PAGILA."CITY"
    WHERE "city" ILIKE 'A%'                -- starts with “A”
       OR "city" LIKE '%-%'                -- contains a hyphen
),
"cte_rental_hours" AS (
    SELECT
        fc."category_id",
        DATEDIFF(
            'hour',
            TRY_TO_TIMESTAMP(r."rental_date"),
            TRY_TO_TIMESTAMP(r."return_date")
        ) AS "hours"
    FROM PAGILA.PAGILA."RENTAL"        r
    JOIN PAGILA.PAGILA."CUSTOMER"      cu ON r."customer_id"  = cu."customer_id"
    JOIN PAGILA.PAGILA."ADDRESS"       a  ON cu."address_id"  = a."address_id"
    JOIN "cte_cities"                  c  ON a."city_id"      = c."city_id"
    JOIN PAGILA.PAGILA."INVENTORY"     i  ON r."inventory_id" = i."inventory_id"
    JOIN PAGILA.PAGILA."FILM_CATEGORY" fc ON i."film_id"      = fc."film_id"
    WHERE TRY_TO_TIMESTAMP(r."rental_date") IS NOT NULL
      AND TRY_TO_TIMESTAMP(r."return_date") IS NOT NULL
),
"cte_category_totals" AS (
    SELECT
        "category_id",
        SUM("hours") AS "total_hours"
    FROM "cte_rental_hours"
    GROUP BY "category_id"
)
SELECT
    cat."name"        AS "category_name",
    ct."total_hours"
FROM "cte_category_totals" ct
JOIN PAGILA.PAGILA."CATEGORY" cat ON ct."category_id" = cat."category_id"
ORDER BY ct."total_hours" DESC NULLS LAST
LIMIT 1;