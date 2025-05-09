WITH rentals_by_store_month AS (
    SELECT
        S."store_id",
        YEAR(CAST(R."rental_date" AS TIMESTAMP_NTZ))  AS "year",
        MONTH(CAST(R."rental_date" AS TIMESTAMP_NTZ)) AS "month",
        COUNT(*)                                      AS "total_rentals"
    FROM
        SQLITE_SAKILA.SQLITE_SAKILA.RENTAL R
        JOIN SQLITE_SAKILA.SQLITE_SAKILA.STAFF  S
          ON R."staff_id" = S."staff_id"
    GROUP BY
        S."store_id",
        YEAR(CAST(R."rental_date" AS TIMESTAMP_NTZ)),
        MONTH(CAST(R."rental_date" AS TIMESTAMP_NTZ))
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY "store_id" ORDER BY "total_rentals" DESC) AS "rnk"
    FROM rentals_by_store_month
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM ranked
WHERE "rnk" = 1
ORDER BY
    "store_id",
    "year",
    "month";