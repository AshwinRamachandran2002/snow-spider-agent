/* ------------------------------------------------------------
   Proportion of January-2020 first-purchase users
   who came back (placed ≥1 extra order) between
   1-Feb-2020 and 31-Dec-2020
   ------------------------------------------------------------ */
WITH first_purchase_2020 AS (          -- every user’s 1st order in CY-2020
    SELECT
        "user_id",
        MIN("created_at") AS "first_purchase_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "created_at" BETWEEN 1577836800000000          -- 01-Jan-2020 00:00:00
                          AND 1609459199000000           -- 31-Dec-2020 23:59:59
    GROUP BY "user_id"
),
jan2020_cohort AS (                   -- users whose 1st 2020 order was in January
    SELECT "user_id"
    FROM first_purchase_2020
    WHERE "first_purchase_ts" BETWEEN 1577836800000000   -- 01-Jan-2020
                                 AND 1580515199000000    -- 31-Jan-2020 23:59:59
),
returned_later_2020 AS (              -- cohort users who ordered again Feb-Dec 2020
    SELECT DISTINCT o."user_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN jan2020_cohort c
      ON o."user_id" = c."user_id"
    WHERE o."created_at" >  1580515199000000            -- after 31-Jan-2020
      AND o."created_at" <= 1609459199000000            -- up to 31-Dec-2020
)
SELECT
    COUNT(*)                                   AS "cohort_size",
    (SELECT COUNT(*) FROM returned_later_2020) AS "returning_users",
    (SELECT COUNT(*) FROM returned_later_2020) * 1.0
      / NULLIF(COUNT(*),0)                     AS "return_rate_2020"
FROM jan2020_cohort;