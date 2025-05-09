SELECT
  age_group,
  COUNT(*) AS user_count
FROM (
  SELECT
    CASE
      WHEN birth_date IS NULL THEN 'others'
      WHEN age BETWEEN 20 AND 29 THEN '20s'
      WHEN age BETWEEN 30 AND 39 THEN '30s'
      WHEN age BETWEEN 40 AND 49 THEN '40s'
      WHEN age BETWEEN 50 AND 59 THEN '50s'
      ELSE 'others'
    END AS age_group
  FROM (
    SELECT
      "birth_date",
      CAST((julianday('now') - julianday("birth_date")) / 365.25 AS INTEGER) AS age
    FROM "mst_users"
  )
)
GROUP BY age_group
ORDER BY age_group;