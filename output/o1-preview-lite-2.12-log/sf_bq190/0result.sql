WITH FilteredUsers AS (
  SELECT u."gender", u."age"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
  WHERE u."created_at" BETWEEN 1546300800000000 AND 1651363199000000
),
AgeStats AS (
  SELECT "gender", MIN("age") AS "Min_Age", MAX("age") AS "Max_Age"
  FROM FilteredUsers
  GROUP BY "gender"
),
MinAgeCount AS (
  SELECT u."gender", COUNT(*) AS "Users_with_Min_Age"
  FROM FilteredUsers u
  JOIN AgeStats a ON u."gender" = a."gender" AND u."age" = a."Min_Age"
  GROUP BY u."gender"
),
MaxAgeCount AS (
  SELECT u."gender", COUNT(*) AS "Users_with_Max_Age"
  FROM FilteredUsers u
  JOIN AgeStats a ON u."gender" = a."gender" AND u."age" = a."Max_Age"
  GROUP BY u."gender"
)
SELECT
  CASE a."gender"
    WHEN 'M' THEN 'Male'
    WHEN 'F' THEN 'Female'
    ELSE a."gender"
  END AS "Gender",
  a."Min_Age",
  COALESCE(m."Users_with_Min_Age", 0) AS "Users_with_Min_Age",
  a."Max_Age",
  COALESCE(x."Users_with_Max_Age", 0) AS "Users_with_Max_Age"
FROM AgeStats a
LEFT JOIN MinAgeCount m ON a."gender" = m."gender"
LEFT JOIN MaxAgeCount x ON a."gender" = x."gender"
ORDER BY "Gender";