WITH top10 AS (
    SELECT "state",
           COUNT(*) AS "alien_count"
    FROM   "alien_data"
    GROUP  BY "state"
    ORDER  BY "alien_count" DESC
    LIMIT 10
),
state_stats AS (
    SELECT "state",
           AVG("age")                                                  AS "avg_age",
           SUM(CASE WHEN "aggressive" = 0 THEN 1 ELSE 0 END)           AS "friendly_cnt",
           SUM(CASE WHEN "aggressive" = 1 THEN 1 ELSE 0 END)           AS "hostile_cnt"
    FROM   "alien_data"
    GROUP  BY "state"
),
filtered AS (
    SELECT s.*
    FROM   state_stats s
    JOIN   top10 t ON s."state" = t."state"
    WHERE  s."friendly_cnt" > s."hostile_cnt"   -- higher % friendly than hostile
      AND  s."avg_age"     > 200                -- average age exceeds 200
)
SELECT COUNT(*) AS "num_states_meeting_criteria"
FROM   filtered;