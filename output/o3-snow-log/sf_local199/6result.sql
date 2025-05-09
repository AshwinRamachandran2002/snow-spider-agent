WITH "RENTALS_BY_MONTH" AS (
    SELECT
        s."store_id"                                            AS "store_id",
        YEAR(TO_TIMESTAMP(r."rental_date"))                     AS "year",
        MONTH(TO_TIMESTAMP(r."rental_date"))                    AS "month",
        COUNT(*)                                                AS "total_rentals"
    FROM
        "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r
        JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."STAFF"  s
          ON r."staff_id" = s."staff_id"
    GROUP BY
        s."store_id",
        YEAR(TO_TIMESTAMP(r."rental_date")),
        MONTH(TO_TIMESTAMP(r."rental_date"))
),
"RANKED" AS (
    SELECT
        "store_id",
        "year",
        "month",
        "total_rentals",
        ROW_NUMBER() OVER (PARTITION BY "store_id"
                           ORDER BY "total_rentals" DESC NULLS LAST) AS "rn"
    FROM "RENTALS_BY_MONTH"
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM
    "RANKED"
WHERE
    "rn" = 1
ORDER BY
    "store_id";