WITH monthly_rentals AS (
    SELECT
        st."store_id",
        EXTRACT(YEAR  FROM TO_TIMESTAMP(re."rental_date"))  AS "year",
        EXTRACT(MONTH FROM TO_TIMESTAMP(re."rental_date"))  AS "month",
        COUNT(*)                                          AS "total_rentals"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.RENTAL  re
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.STAFF   st
          ON re."staff_id" = st."staff_id"
    GROUP BY
        st."store_id",
        EXTRACT(YEAR  FROM TO_TIMESTAMP(re."rental_date")),
        EXTRACT(MONTH FROM TO_TIMESTAMP(re."rental_date"))
), max_per_store AS (
    SELECT
        "store_id",
        MAX("total_rentals") AS "max_total"
    FROM monthly_rentals
    GROUP BY "store_id"
)
SELECT
    mr."store_id",
    mr."year",
    mr."month",
    mr."total_rentals"
FROM monthly_rentals mr
JOIN max_per_store ms
      ON mr."store_id"      = ms."store_id"
     AND mr."total_rentals" = ms."max_total"
ORDER BY
    mr."store_id",
    mr."year"  DESC NULLS LAST,
    mr."month" DESC NULLS LAST;