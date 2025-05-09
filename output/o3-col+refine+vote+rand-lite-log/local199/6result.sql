SELECT  result."store_id",
        result."year",
        result."month",
        result."total_rentals"
FROM   (
        SELECT  s."store_id",
                strftime('%Y', r."rental_date") AS "year",
                strftime('%m', r."rental_date") AS "month",
                COUNT(*)                       AS "total_rentals",
                RANK() OVER (PARTITION BY s."store_id"
                             ORDER BY COUNT(*) DESC) AS "rank_in_store"
        FROM    "rental" AS r
        JOIN    "staff"  AS s ON r."staff_id" = s."staff_id"
        GROUP BY s."store_id",
                 strftime('%Y', r."rental_date"),
                 strftime('%m', r."rental_date")
       ) AS result
WHERE  result."rank_in_store" = 1
ORDER BY result."store_id";