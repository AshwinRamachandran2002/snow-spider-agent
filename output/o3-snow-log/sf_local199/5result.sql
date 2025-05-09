WITH "rentals_per_month" AS (
    SELECT
        s."store_id",
        YEAR(CAST(r."rental_date" AS TIMESTAMP))  AS "year",
        MONTH(CAST(r."rental_date" AS TIMESTAMP)) AS "month",
        COUNT(*)                                   AS "total_rentals"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.RENTAL r
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.STAFF  s
      ON r."staff_id" = s."staff_id"
    GROUP BY
        s."store_id",
        YEAR(CAST(r."rental_date" AS TIMESTAMP)),
        MONTH(CAST(r."rental_date" AS TIMESTAMP))
),
"ranked" AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "store_id"
            ORDER BY "total_rentals" DESC, "year", "month"
        ) AS "rn"
    FROM "rentals_per_month"
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM "ranked"
WHERE "rn" = 1
ORDER BY "store_id";