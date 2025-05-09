/* Difference in the number of the oldest vs. youngest users
   who registered between 01-Jan-2019 and 30-Apr-2022 */

WITH range_users AS (   -- users within the specified registration window
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000          -- 2019-01-01 00:00:00
                          AND     1651363199000000       -- 2022-04-30 23:59:59
),
extremes AS (           -- identify youngest and oldest ages in that window
    SELECT 
        MIN("age") AS youngest_age,
        MAX("age") AS oldest_age
    FROM range_users
)

SELECT
    /* count(oldest) minus count(youngest) */
    COUNT(CASE WHEN ru."age" = ex.oldest_age   THEN 1 END)
  - COUNT(CASE WHEN ru."age" = ex.youngest_age THEN 1 END)
    AS "difference_oldest_vs_youngest"
FROM range_users ru
CROSS JOIN extremes ex;