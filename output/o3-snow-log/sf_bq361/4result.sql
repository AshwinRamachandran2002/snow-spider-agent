WITH first_purchase AS (  -- find each user's first-ever order
    SELECT
        "user_id",
        MIN(TO_TIMESTAMP("created_at"/1000000)) AS "first_purchase_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
),
cohort AS (              -- keep only those whose first purchase was in 2020-01
    SELECT
        fp."user_id"
    FROM first_purchase fp
    WHERE TO_CHAR(fp."first_purchase_ts", 'YYYY-MM') = '2020-01'
),
returned_users AS (      -- among that cohort, who purchased again Feb-Dec 2020?
    SELECT DISTINCT
        o."user_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN cohort c
      ON o."user_id" = c."user_id"
    WHERE TO_CHAR(TO_TIMESTAMP(o."created_at"/1000000), 'YYYY-MM')
          BETWEEN '2020-02' AND '2020-12'
)
SELECT
    COUNT(DISTINCT ru."user_id")      AS "returned_users",
    COUNT(DISTINCT c."user_id")       AS "cohort_size",
    COUNT(DISTINCT ru."user_id")
      / NULLIF(COUNT(DISTINCT c."user_id"),0)::FLOAT  AS "retention_proportion"
FROM cohort c
LEFT JOIN returned_users ru
  ON c."user_id" = ru."user_id";