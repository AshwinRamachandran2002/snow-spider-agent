WITH rental_counts AS (
    SELECT
        S."store_id",
        EXTRACT(YEAR FROM CAST(R."rental_date" AS TIMESTAMP)) AS "year",
        EXTRACT(MONTH FROM CAST(R."rental_date" AS TIMESTAMP)) AS "month",
        COUNT(*) AS "total_rentals"
    FROM
        SQLITE_SAKILA.SQLITE_SAKILA.RENTAL R
        JOIN SQLITE_SAKILA.SQLITE_SAKILA.STAFF S ON R."staff_id" = S."staff_id"
    GROUP BY
        S."store_id",
        EXTRACT(YEAR FROM CAST(R."rental_date" AS TIMESTAMP)),
        EXTRACT(MONTH FROM CAST(R."rental_date" AS TIMESTAMP))
)
SELECT
    RC."store_id",
    RC."year",
    RC."month",
    RC."total_rentals"
FROM
    rental_counts RC
    JOIN (
        SELECT
            "store_id",
            MAX("total_rentals") AS "max_total_rentals"
        FROM
            rental_counts
        GROUP BY
            "store_id"
    ) MRC ON RC."store_id" = MRC."store_id" AND RC."total_rentals" = MRC."max_total_rentals"
ORDER BY
    RC."store_id";