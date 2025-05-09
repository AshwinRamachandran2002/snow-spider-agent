WITH state_stats AS (
    SELECT LOWER("state")                             AS "state",
           COUNT(*)                                   AS "population",
           SUM(CASE WHEN "aggressive" = 0 THEN 1 END) AS "friendly_count",
           SUM(CASE WHEN "aggressive" = 1 THEN 1 END) AS "hostile_count",
           AVG("age")                                 AS "avg_age"
    FROM   "alien_data"
    GROUP  BY LOWER("state")
),
top_states AS (
    SELECT *
    FROM   state_stats
    ORDER  BY "population" DESC
    LIMIT  10
)
SELECT COUNT(*) AS "states_friendly_over_hostile"
FROM   top_states
WHERE  "friendly_count" > "hostile_count"
  AND  "avg_age" > 200;