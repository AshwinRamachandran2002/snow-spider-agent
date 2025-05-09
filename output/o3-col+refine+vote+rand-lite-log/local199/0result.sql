WITH monthly_counts AS (
    SELECT
        st."store_id",
        strftime('%Y', r."rental_date") AS "year",
        strftime('%m', r."rental_date") AS "month",
        COUNT(*)                       AS "total_rentals",
        ROW_NUMBER() OVER (
            PARTITION BY st."store_id"
            ORDER BY COUNT(*) DESC
        )                              AS rn
    FROM "rental" AS r
    JOIN "staff"  AS st ON r."staff_id" = st."staff_id"
    GROUP BY
        st."store_id",
        "year",
        "month"
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM monthly_counts
WHERE rn = 1
ORDER BY "store_id";