SELECT
    "store_id",
    "year",
    "month",
    "total_rentals"
FROM
    (
        SELECT
            "store_id",
            "year",
            "month",
            "total_rentals",
            RANK() OVER (
                PARTITION BY "store_id"
                ORDER BY "total_rentals" DESC NULLS LAST
            ) AS "rank"
        FROM
            (
                SELECT
                    S."store_id",
                    EXTRACT(YEAR FROM TO_TIMESTAMP(R."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF3')) AS "year",
                    EXTRACT(MONTH FROM TO_TIMESTAMP(R."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF3')) AS "month",
                    COUNT(*) AS "total_rentals"
                FROM
                    "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL" R
                    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."STAFF" S ON R."staff_id" = S."staff_id"
                GROUP BY
                    S."store_id",
                    EXTRACT(YEAR FROM TO_TIMESTAMP(R."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF3')),
                    EXTRACT(MONTH FROM TO_TIMESTAMP(R."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF3'))
            ) t
    ) tt
WHERE "rank" = 1;