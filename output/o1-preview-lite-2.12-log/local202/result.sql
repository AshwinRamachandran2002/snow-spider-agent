WITH top_states AS (
  SELECT "state"
  FROM "alien_data"
  GROUP BY "state"
  ORDER BY COUNT(*) DESC
  LIMIT 10
),
state_stats AS (
  SELECT a."state",
    COUNT(*) AS "total_aliens",
    SUM(CASE WHEN a."aggressive" = 0 THEN 1 ELSE 0 END) AS "friendly_count",
    SUM(CASE WHEN a."aggressive" = 1 THEN 1 ELSE 0 END) AS "hostile_count",
    ROUND((SUM(CASE WHEN a."aggressive" = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 4) AS "friendly_percentage",
    ROUND(AVG(a."age"), 4) AS "average_age"
  FROM "alien_data" AS a
  WHERE a."state" IN (SELECT "state" FROM top_states)
  GROUP BY a."state"
)
SELECT COUNT(*) AS "Number_of_states"
FROM state_stats
WHERE "friendly_percentage" > 50 AND "average_age" > 200;