SELECT c."first_name" || ' ' || c."last_name" AS "full_name"
FROM   "customer" AS c
JOIN  (
        SELECT "customer_id",
               AVG("month_change") AS "avg_monthly_change"
        FROM  (
                SELECT "customer_id",
                       ABS("month_total" - LAG("month_total") OVER (PARTITION BY "customer_id"
                                                                    ORDER BY "yyyymm")) AS "month_change"
                FROM  (
                        SELECT "customer_id",
                               strftime('%Y-%m', "payment_date") AS "yyyymm",
                               SUM("amount") AS "month_total"
                        FROM   "payment"
                        GROUP  BY "customer_id", "yyyymm"
                      )
              )
        WHERE  "month_change" IS NOT NULL       -- need two months to form a change
        GROUP  BY "customer_id"
        ORDER  BY "avg_monthly_change" DESC
        LIMIT 1
      ) AS top ON top."customer_id" = c."customer_id";