WITH users_with_age AS (
  SELECT
    user_id,
    /* age as of 2017-01-01 */
    CAST(strftime('%Y','2017-01-01') AS INTEGER)
      - CAST(substr(birth_date,1,4) AS INTEGER)
      - (strftime('%m-%d','2017-01-01') < substr(birth_date,6,5)) AS age
  FROM mst_users
)
SELECT
  CASE
    WHEN age BETWEEN 20 AND 29 THEN '20s'
    WHEN age BETWEEN 30 AND 39 THEN '30s'
    WHEN age BETWEEN 40 AND 49 THEN '40s'
    WHEN age BETWEEN 50 AND 59 THEN '50s'
    ELSE 'others'
  END AS age_category,
  COUNT(*) AS user_count
FROM users_with_age
GROUP BY age_category
ORDER BY age_category;