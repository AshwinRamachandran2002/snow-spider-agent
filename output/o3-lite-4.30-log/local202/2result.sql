SELECT COUNT(*) AS "num_states"
FROM (
  WITH top10 AS (
    SELECT "state"
    FROM "alien_data"
    GROUP BY "state"
    ORDER BY COUNT(*) DESC
    LIMIT 10
  )
  SELECT a."state"
  FROM "alien_data" AS a
  JOIN top10 t ON a."state" = t."state"
  GROUP BY a."state"
  HAVING AVG(a."age") > 200
     AND (1.0 * SUM(CASE WHEN a."aggressive" = 0 THEN 1 ELSE 0 END) / COUNT(*)) >
         (1.0 * SUM(CASE WHEN a."aggressive" = 1 THEN 1 ELSE 0 END) / COUNT(*))
) qualified;