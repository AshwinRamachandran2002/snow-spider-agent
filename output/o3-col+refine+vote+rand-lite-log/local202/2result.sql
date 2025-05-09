WITH top_states AS (
    -- 1. Identify the 10 states with the largest alien populations
    SELECT "state"
    FROM "alien_data"
    GROUP BY "state"
    ORDER BY COUNT(*) DESC
    LIMIT 10
),
state_stats AS (
    -- 2. For those states, compute average age and friendly/hostile counts
    SELECT
        ad."state",
        AVG(ad."age")                                                  AS avg_age,
        SUM(CASE WHEN ad."aggressive" = 0 THEN 1 ELSE 0 END)           AS friendly,
        SUM(CASE WHEN ad."aggressive" = 1 THEN 1 ELSE 0 END)           AS hostile
    FROM "alien_data" AS ad
    JOIN top_states AS ts
      ON ad."state" = ts."state"
    GROUP BY ad."state"
)
-- 3. Count how many states meet both criteria
SELECT
    COUNT(*) AS num_states_meeting_criteria
FROM state_stats
WHERE avg_age  > 200          -- average alien age exceeds 200
  AND friendly > hostile;     -- higher percentage friendly than hostile