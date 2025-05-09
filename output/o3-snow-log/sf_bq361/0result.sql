/*---------------------------------------------------------------
  Proportion of January-2020 cohort users that returned in the
  subsequent months (Feb-Dec) of calendar year 2020
----------------------------------------------------------------*/
WITH jan20_cohort AS (          -- 1️⃣  Users whose very first order was in Jan-2020
    SELECT  "user_id"
    FROM    (
                SELECT  "user_id",
                        MIN("created_at") AS "first_purchase_ts"
                FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
                GROUP   BY "user_id"
            )
    WHERE   "first_purchase_ts" BETWEEN 1577836800000000  -- 2020-01-01 00:00:00
                                    AND     1580515200000000  -- 2020-02-01 00:00:00 (exclusive)
), 
subsequent_orders AS (          -- 2️⃣  Orders placed AFTER January-2020 but before 2021
    SELECT  o."user_id",
            TO_CHAR( TO_TIMESTAMP_LTZ( o."created_at" / 1000000 ), 'YYYY-MM') AS "order_month"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"  o
    JOIN    jan20_cohort                                      c  ON o."user_id" = c."user_id"
    WHERE   o."created_at" >  1580515200000000        -- after 2020-02-01 00:00:00
      AND   o."created_at" <  1609459200000000        -- before 2021-01-01 00:00:00
)
SELECT  "order_month",
        COUNT(DISTINCT "user_id")                           AS "returning_users",
        (SELECT COUNT(*) FROM jan20_cohort)                AS "cohort_size",
        ROUND(
              COUNT(DISTINCT "user_id") 
              / (SELECT COUNT(*)::FLOAT FROM jan20_cohort)
             , 4)                                          AS "returning_prop"
FROM    subsequent_orders
GROUP   BY "order_month"
ORDER   BY "order_month";