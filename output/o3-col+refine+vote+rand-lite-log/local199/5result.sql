SELECT  t."store_id",
        t."year",
        t."month",
        t."total_rentals"
FROM   (
        SELECT  s."store_id",
                strftime('%Y', r."rental_date") AS "year",
                strftime('%m', r."rental_date") AS "month",
                COUNT(*)                       AS "total_rentals",
                ROW_NUMBER() OVER (
                    PARTITION BY s."store_id"
                    ORDER BY COUNT(*) DESC
                ) AS rn
        FROM    "rental" AS r
        JOIN    "staff"  AS s
               ON r."staff_id" = s."staff_id"
        GROUP BY s."store_id",
                 "year",
                 "month"
       ) AS t
WHERE  t.rn = 1;