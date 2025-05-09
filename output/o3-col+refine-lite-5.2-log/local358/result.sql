-- How many users fall into each age group: 20s, 30s, 40s, 50s, and others
SELECT
  age_group,
  COUNT(*) AS user_count
FROM (
  SELECT
    CASE
      WHEN CAST(strftime('%Y','now') - strftime('%Y',"birth_date")
               - (strftime('%m-%d','now') < strftime('%m-%d',"birth_date")) AS INTEGER)
           BETWEEN 20 AND 29 THEN '20s'
      WHEN CAST(strftime('%Y','now') - strftime('%Y',"birth_date")
               - (strftime('%m-%d','now') < strftime('%m-%d',"birth_date")) AS INTEGER)
           BETWEEN 30 AND 39 THEN '30s'
      WHEN CAST(strftime('%Y','now') - strftime('%Y',"birth_date")
               - (strftime('%m-%d','now') < strftime('%m-%d',"birth_date")) AS INTEGER)
           BETWEEN 40 AND 49 THEN '40s'
      WHEN CAST(strftime('%Y','now') - strftime('%Y',"birth_date")
               - (strftime('%m-%d','now') < strftime('%m-%d',"birth_date")) AS INTEGER)
           BETWEEN 50 AND 59 THEN '50s'
      ELSE 'others'
    END AS age_group
  FROM "mst_users"
) AS t
GROUP BY age_group
ORDER BY
  CASE age_group
    WHEN '20s' THEN 1
    WHEN '30s' THEN 2
    WHEN '40s' THEN 3
    WHEN '50s' THEN 4
    ELSE 5
  END;