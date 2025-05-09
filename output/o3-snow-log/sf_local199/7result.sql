/* 1)  Count rentals per store, year and month
   2)  Rank the months inside every store by the number of rentals
   3)  Keep only the month(s) that obtained the highest total per store   */

WITH rentals_by_month AS (
    SELECT
        inv."store_id",
        EXTRACT(year  FROM TO_TIMESTAMP(ren."rental_date"))  AS "year",
        EXTRACT(month FROM TO_TIMESTAMP(ren."rental_date"))  AS "month",
        COUNT(*)                                           AS "total_rentals"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"    ren
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY" inv
          ON ren."inventory_id" = inv."inventory_id"
    GROUP BY
        inv."store_id",
        EXTRACT(year  FROM TO_TIMESTAMP(ren."rental_date")),
        EXTRACT(month FROM TO_TIMESTAMP(ren."rental_date"))
),
ranked AS (
    SELECT
        rbm.*,
        RANK() OVER (PARTITION BY rbm."store_id"
                     ORDER BY rbm."total_rentals" DESC) AS "rnk"
    FROM rentals_by_month rbm
)
SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM ranked
WHERE "rnk" = 1
ORDER BY
    "store_id" ASC,
    "year"  ASC,
    "month" ASC;