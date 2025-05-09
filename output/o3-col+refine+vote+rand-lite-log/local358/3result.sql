SELECT
  CASE
    WHEN age BETWEEN 20 AND 29 THEN '20s'
    WHEN age BETWEEN 30 AND 39 THEN '30s'
    WHEN age BETWEEN 40 AND 49 THEN '40s'
    WHEN age BETWEEN 50 AND 59 THEN '50s'
    ELSE 'others'
  END AS age_band,
  COUNT(*) AS users_cnt
FROM (
  SELECT
    "user_id",
    CAST(
      strftime('%Y','now') - substr("birth_date",1,4) -
      (strftime('%m-%d','now') < substr("birth_date",6,5))
      AS INTEGER
    ) AS age
  FROM "mst_users"
)
GROUP BY age_band
ORDER BY
  CASE age_band
    WHEN '20s' THEN 1
    WHEN '30s' THEN 2
    WHEN '40s' THEN 3
    WHEN '50s' THEN 4
    ELSE 5
  END;