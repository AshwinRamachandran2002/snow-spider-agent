SELECT
  CASE
    WHEN age BETWEEN 20 AND 29 THEN '20s'
    WHEN age BETWEEN 30 AND 39 THEN '30s'
    WHEN age BETWEEN 40 AND 49 THEN '40s'
    WHEN age BETWEEN 50 AND 59 THEN '50s'
    ELSE 'Others'
  END AS "Age Category",
  COUNT(*) AS "Number of Users"
FROM (
  SELECT
    "user_id",
    CAST((julianday('now') - julianday("birth_date")) / 365.25 AS INTEGER) AS age
  FROM "mst_users"
  WHERE "birth_date" IS NOT NULL AND "birth_date" != ''
)
GROUP BY "Age Category";