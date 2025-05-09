/*  Proportion of January-2020 first-purchase users who came back
    in each subsequent month (Feb-Dec 2020)                     */
WITH cohort AS (
    SELECT  "user_id",
            MIN( TO_TIMESTAMP("created_at" / 1000000)::DATE ) AS "first_purchase_date"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
    HAVING  "first_purchase_date" BETWEEN '2020-01-01' AND '2020-01-31'
),
cohort_size AS (
    SELECT COUNT(*) AS "total_users" FROM cohort
)
SELECT  DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000)) AS "month_2020",
        COUNT(DISTINCT o."user_id")                                AS "returning_users",
        cs."total_users",
        COUNT(DISTINCT o."user_id") / cs."total_users"::FLOAT      AS "return_proportion"
FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
JOIN    cohort        c  ON o."user_id" = c."user_id"
CROSS   JOIN cohort_size cs
WHERE   DATE_TRUNC('year',  TO_TIMESTAMP(o."created_at" / 1000000)) = '2020-01-01'      -- only 2020
  AND   DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000)) >  '2020-01-01'      -- Feb-Dec
GROUP BY "month_2020", cs."total_users"
ORDER BY "month_2020";