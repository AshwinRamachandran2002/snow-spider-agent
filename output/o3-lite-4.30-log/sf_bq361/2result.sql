WITH cohort AS (
    /* users whose very first order was placed in Jan‑2020 */
    SELECT  "user_id",
            MIN("created_at") AS first_ts
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
    HAVING  EXTRACT(YEAR  FROM TO_TIMESTAMP_NTZ(first_ts/1000000)) = 2020
       AND  EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ(first_ts/1000000)) = 1
), returns AS (
    /* Feb‑Dec 2020 purchases made by those cohort users */
    SELECT  DISTINCT
            c."user_id",
            EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ(o."created_at"/1000000)) AS return_month
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN    cohort c
           ON c."user_id" = o."user_id"
    WHERE   o."created_at" > c.first_ts
      AND   EXTRACT(YEAR  FROM TO_TIMESTAMP_NTZ(o."created_at"/1000000)) = 2020
      AND   EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ(o."created_at"/1000000)) > 1   -- Feb‑Dec
)
SELECT  LPAD(return_month::VARCHAR, 2, '0') AS month,
        ROUND(
            COUNT(DISTINCT "user_id")::FLOAT
            /
            NULLIF((SELECT COUNT(*) FROM cohort), 0)
        , 4) AS proportion_returned
FROM    returns
GROUP BY return_month
ORDER BY return_month;