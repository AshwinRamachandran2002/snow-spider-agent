WITH youngest AS (
  SELECT
    "gender",
    MIN("age") AS "Age"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
  WHERE "gender" IN ('M', 'F')
    AND "created_at" BETWEEN 1546300800000000 AND 1651276800000000
  GROUP BY "gender"
),
youngest_counts AS (
  SELECT
    CASE u."gender"
      WHEN 'M' THEN 'Male'
      WHEN 'F' THEN 'Female'
      ELSE u."gender"
    END AS "Gender",
    'Youngest' AS "Age_Type",
    u."age" AS "Age",
    COUNT(*) AS "Count"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
  INNER JOIN youngest y ON u."gender" = y."gender" AND u."age" = y."Age"
  WHERE u."created_at" BETWEEN 1546300800000000 AND 1651276800000000
  GROUP BY "Gender", "Age_Type", u."age"
),
oldest AS (
  SELECT
    "gender",
    MAX("age") AS "Age"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
  WHERE "gender" IN ('M', 'F')
    AND "created_at" BETWEEN 1546300800000000 AND 1651276800000000
  GROUP BY "gender"
),
oldest_counts AS (
  SELECT
    CASE u."gender"
      WHEN 'M' THEN 'Male'
      WHEN 'F' THEN 'Female'
      ELSE u."gender"
    END AS "Gender",
    'Oldest' AS "Age_Type",
    u."age" AS "Age",
    COUNT(*) AS "Count"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
  INNER JOIN oldest o ON u."gender" = o."gender" AND u."age" = o."Age"
  WHERE u."created_at" BETWEEN 1546300800000000 AND 1651276800000000
  GROUP BY "Gender", "Age_Type", u."age"
)
SELECT "Gender", "Age_Type", "Age", "Count"
FROM youngest_counts
UNION ALL
SELECT "Gender", "Age_Type", "Age", "Count"
FROM oldest_counts
ORDER BY "Gender", "Age_Type";