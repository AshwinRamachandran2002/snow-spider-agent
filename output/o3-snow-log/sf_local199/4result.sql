WITH "RENTALS_BY_MONTH" AS (
    SELECT
        st."store_id",
        EXTRACT(YEAR  FROM TO_TIMESTAMP(re."rental_date"))  AS "year",
        EXTRACT(MONTH FROM TO_TIMESTAMP(re."rental_date"))  AS "month",
        COUNT(*)                                           AS "total_rentals"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.RENTAL  re
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.STAFF   st
          ON re."staff_id" = st."staff_id"
    WHERE re."rental_date" IS NOT NULL
    GROUP BY st."store_id",
             EXTRACT(YEAR  FROM TO_TIMESTAMP(re."rental_date")),
             EXTRACT(MONTH FROM TO_TIMESTAMP(re."rental_date"))
),
"RANKED" AS (
    SELECT
        "store_id",
        "year",
        "month",
        "total_rentals",
        RANK() OVER (PARTITION BY "store_id"
                     ORDER BY "total_rentals" DESC) AS "rk"
    FROM "RENTALS_BY_MONTH"
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM "RANKED"
WHERE "rk" = 1
ORDER BY "store_id";