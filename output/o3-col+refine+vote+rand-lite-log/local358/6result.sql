SELECT
  CASE
    WHEN (2017 - CAST(substr("birth_date", 1, 4) AS INTEGER)) BETWEEN 20 AND 29 THEN '20s'
    WHEN (2017 - CAST(substr("birth_date", 1, 4) AS INTEGER)) BETWEEN 30 AND 39 THEN '30s'
    WHEN (2017 - CAST(substr("birth_date", 1, 4) AS INTEGER)) BETWEEN 40 AND 49 THEN '40s'
    WHEN (2017 - CAST(substr("birth_date", 1, 4) AS INTEGER)) BETWEEN 50 AND 59 THEN '50s'
    ELSE 'others'
  END AS "age_group",
  COUNT(*) AS "user_count"
FROM "mst_users"
GROUP BY "age_group"
ORDER BY "age_group";