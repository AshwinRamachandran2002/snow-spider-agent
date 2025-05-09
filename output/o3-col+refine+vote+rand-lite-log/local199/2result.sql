WITH rentals_by_month AS (
    SELECT  s."store_id",
            strftime('%Y', r."rental_date") AS "year",
            strftime('%m', r."rental_date") AS "month",
            COUNT(*)                      AS "total_rentals",
            ROW_NUMBER() OVER (
                PARTITION BY s."store_id"
                ORDER BY COUNT(*) DESC
            )                             AS rn
    FROM   "rental" AS r
    JOIN   "staff"  AS s ON r."staff_id" = s."staff_id"
    GROUP  BY s."store_id", "year", "month"
)
SELECT  "store_id",
        "year",
        "month",
        "total_rentals"
FROM    rentals_by_month
WHERE   rn = 1
ORDER BY "store_id";