/*  Year-month with the highest number of rentals made by each store’s staff */
WITH rental_store_month AS (
    SELECT
        s."store_id",
        EXTRACT(YEAR  FROM TO_DATE(r."rental_date")) AS "year",
        EXTRACT(MONTH FROM TO_DATE(r."rental_date")) AS "month",
        COUNT(*)                                        AS "total_rentals"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"  r
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."STAFF"   s
      ON r."staff_id" = s."staff_id"
    GROUP BY
        s."store_id",
        EXTRACT(YEAR  FROM TO_DATE(r."rental_date")),
        EXTRACT(MONTH FROM TO_DATE(r."rental_date"))
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "store_id"
            ORDER BY "total_rentals" DESC, "year", "month"
        ) AS rn
    FROM rental_store_month
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM ranked
WHERE rn = 1
ORDER BY "store_id";