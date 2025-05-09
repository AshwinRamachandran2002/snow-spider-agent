WITH rental_counts AS (
    SELECT
        s."store_id",
        EXTRACT(YEAR FROM TO_TIMESTAMP(r."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF3')) AS "Year",
        EXTRACT(MONTH FROM TO_TIMESTAMP(r."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF3')) AS "Month",
        COUNT(*) AS "Total_Rentals"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" r
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."STAFF" s
        ON r."staff_id" = s."staff_id"
    GROUP BY
        s."store_id",
        EXTRACT(YEAR FROM TO_TIMESTAMP(r."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF3')),
        EXTRACT(MONTH FROM TO_TIMESTAMP(r."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF3'))
)
SELECT
    "store_id",
    "Year",
    "Month",
    "Total_Rentals"
FROM
(
    SELECT
        rc.*,
        ROW_NUMBER() OVER (
            PARTITION BY rc."store_id"
            ORDER BY rc."Total_Rentals" DESC NULLS LAST
        ) AS rn
    FROM rental_counts rc
)
WHERE rn = 1
ORDER BY "store_id";