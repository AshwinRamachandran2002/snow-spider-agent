SELECT
  age_category,
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
    END AS age_category
  FROM (
    SELECT
      birth_date,
      -- precise age at today
      CAST(
        (strftime('%Y', 'now') - strftime('%Y', birth_date))
        - (strftime('%m-%d', 'now') < strftime('%m-%d', birth_date))
        AS INTEGER
      ) AS age
    FROM mst_users
  )
)
GROUP BY age_category
ORDER BY
  CASE age_category
    WHEN '20s' THEN 1
    WHEN '30s' THEN 2
    WHEN '40s' THEN 3
    WHEN '50s' THEN 4
    ELSE 5
  END;