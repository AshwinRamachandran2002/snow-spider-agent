WITH monthly_rentals AS (
    SELECT
        i."store_id",
        strftime('%Y', r."rental_date") AS "year",
        strftime('%m', r."rental_date") AS "month",
        COUNT(*) AS "total_rentals"
    FROM "rental"    AS r
    JOIN "inventory" AS i
          ON i."inventory_id" = r."inventory_id"
    GROUP BY i."store_id", "year", "month"
),
ranked AS (
    SELECT
        "store_id",
        "year",
        "month",
        "total_rentals",
        ROW_NUMBER() OVER (
            PARTITION BY "store_id"
            ORDER BY "total_rentals" DESC, "year", "month"
        ) AS rn
    FROM monthly_rentals
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM ranked
WHERE rn = 1
ORDER BY "store_id";