WITH filtered AS (
  SELECT "age"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
  WHERE "created_at" BETWEEN 1546300800000000 AND 1651363199000000
),
bounds AS (
  SELECT MIN("age") AS youngest_age,
         MAX("age") AS oldest_age
  FROM filtered
)
SELECT
  SUM(CASE WHEN f."age" = b.oldest_age THEN 1 ELSE 0 END)
  -
  SUM(CASE WHEN f."age" = b.youngest_age THEN 1 ELSE 0 END)
  AS "users_difference"
FROM filtered f, bounds b;