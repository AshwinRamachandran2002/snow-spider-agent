-- Task: List each of the top 10 states by alien population along with the percentage of friendly aliens and the average age of aliens in that state.
WITH top_states AS (
  SELECT "state"
  FROM "alien_data"
  GROUP BY "state"
  ORDER BY COUNT(*) DESC
  LIMIT 10
)
SELECT a."state",
  ROUND((SUM(CASE WHEN a."aggressive" = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 4) AS "friendly_percentage",
  ROUND(AVG(a."age"), 4) AS "average_age"
FROM "alien_data" AS a
WHERE a."state" IN (SELECT "state" FROM top_states)
GROUP BY a."state";