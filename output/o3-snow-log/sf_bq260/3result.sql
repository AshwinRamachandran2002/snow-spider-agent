WITH filtered AS (   -- keep users created between 2019-01-01 and 2022-04-30
    SELECT "id",
           "gender",
           "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000        -- 2019-01-01 00:00:00
                          AND 1651363199000000         -- 2022-04-30 23:59:59
),
extremes AS (        -- find youngest & oldest age per gender
    SELECT "gender",
           MIN("age") AS "youngest_age",
           MAX("age") AS "oldest_age"
    FROM filtered
    GROUP BY "gender"
)
SELECT
      e."gender",
      e."youngest_age",
      SUM(IFF(f."age" = e."youngest_age", 1, 0)) AS "num_of_youngest_users",
      e."oldest_age",
      SUM(IFF(f."age" = e."oldest_age", 1, 0))   AS "num_of_oldest_users"
FROM   extremes e
JOIN   filtered f
  ON   f."gender" = e."gender"
GROUP BY
      e."gender",
      e."youngest_age",
      e."oldest_age"
ORDER BY
      e."gender";