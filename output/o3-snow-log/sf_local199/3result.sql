WITH "rentals_by_month" AS (
    SELECT
        st."store_id",
        EXTRACT(year  FROM TO_TIMESTAMP(r."rental_date")) AS "year",
        EXTRACT(month FROM TO_TIMESTAMP(r."rental_date")) AS "month",
        COUNT(*) AS "total_rentals"
    FROM
        "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r
        JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."STAFF" st
          ON r."staff_id" = st."staff_id"
    GROUP BY
        st."store_id",
        EXTRACT(year  FROM TO_TIMESTAMP(r."rental_date")),
        EXTRACT(month FROM TO_TIMESTAMP(r."rental_date"))
),
"ranked" AS (
    SELECT
        rbm.*,
        ROW_NUMBER() OVER (
            PARTITION BY rbm."store_id"
            ORDER BY rbm."total_rentals" DESC
        ) AS "rn"
    FROM
        "rentals_by_month" rbm
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM
    "ranked"
WHERE
    "rn" = 1
ORDER BY
    "store_id";