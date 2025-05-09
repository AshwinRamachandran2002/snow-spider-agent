WITH calc_age AS (
  SELECT
    user_id,
    -- calculate current age in years
    (CAST(strftime('%Y','now') AS INTEGER) - CAST(substr(birth_date,1,4) AS INTEGER))
      - (strftime('%m-%d','now') < substr(birth_date,6)) AS age
  FROM mst_users
  WHERE birth_date IS NOT NULL AND birth_date <> ''
)

SELECT
  CASE
    WHEN age BETWEEN 20 AND 29 THEN '20s'
    WHEN age BETWEEN 30 AND 39 THEN '30s'
    WHEN age BETWEEN 40 AND 49 THEN '40s'
    WHEN age BETWEEN 50 AND 59 THEN '50s'
    ELSE 'Others'
  END AS age_category,
  COUNT(*) AS user_count
FROM calc_age
GROUP BY age_category
ORDER BY
  CASE age_category
    WHEN '20s'   THEN 1
    WHEN '30s'   THEN 2
    WHEN '40s'   THEN 3
    WHEN '50s'   THEN 4
    ELSE 5
  END;