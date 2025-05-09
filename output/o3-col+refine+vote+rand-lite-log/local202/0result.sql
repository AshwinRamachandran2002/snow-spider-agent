WITH top_states AS (
    SELECT state
    FROM alien_data
    GROUP BY state
    ORDER BY COUNT(*) DESC
    LIMIT 10
),
state_stats AS (
    SELECT
        state,
        SUM(CASE WHEN aggressive = 0 THEN 1 ELSE 0 END) AS friendly_cnt,
        SUM(CASE WHEN aggressive = 1 THEN 1 ELSE 0 END) AS hostile_cnt,
        AVG(age)                                         AS avg_age
    FROM alien_data
    WHERE state IN (SELECT state FROM top_states)
    GROUP BY state
),
qualifying_states AS (
    SELECT state
    FROM state_stats
    WHERE friendly_cnt > hostile_cnt      -- higher % friendly than hostile
      AND avg_age > 200                   -- average age exceeds 200
)
SELECT COUNT(*) AS qualifying_states
FROM qualifying_states;