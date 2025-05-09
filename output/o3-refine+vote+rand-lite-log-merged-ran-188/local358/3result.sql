SELECT
  age_group,
  COUNT(*) AS user_count
FROM (
  SELECT
    CASE
      WHEN age BETWEEN 20 AND 29 THEN '20s'
      WHEN age BETWEEN 30 AND 39 THEN '30s'
      WHEN age BETWEEN 40 AND 49 THEN '40s'
      WHEN age BETWEEN 50 AND 59 THEN '50s'
      ELSE 'others'
    END AS age_group
  FROM (
    /* calculate current age in years for each user */
    SELECT
      (strftime('%Y', 'now') - strftime('%Y', "birth_date")
       - (strftime('%m-%d', 'now') < strftime('%m-%d', "birth_date"))) AS age
    FROM "mst_users"
    WHERE "birth_date" IS NOT NULL
  )
)
GROUP BY age_group
ORDER BY
  CASE age_group
    WHEN '20s' THEN 1
    WHEN '30s' THEN 2
    WHEN '40s' THEN 3
    WHEN '50s' THEN 4
    ELSE 5
  END;