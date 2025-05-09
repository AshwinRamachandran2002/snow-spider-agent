WITH monthly_totals AS (
    SELECT
        s."store_id",
        strftime('%Y', r."rental_date") AS "year",
        strftime('%m', r."rental_date") AS "month",
        COUNT(*) AS "total_rentals"
    FROM "rental" AS r
    JOIN "staff"  AS s
      ON r."staff_id" = s."staff_id"
    GROUP BY
        s."store_id",
        strftime('%Y', r."rental_date"),
        strftime('%m', r."rental_date")
),
ranked_months AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY "store_id"
                     ORDER BY "total_rentals" DESC) AS rk
    FROM monthly_totals
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM ranked_months
WHERE rk = 1
ORDER BY "store_id";