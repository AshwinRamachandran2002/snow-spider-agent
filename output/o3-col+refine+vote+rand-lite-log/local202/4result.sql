WITH top_states AS (
    SELECT state
    FROM alien_data
    WHERE state IS NOT NULL
    GROUP BY state
    ORDER BY COUNT(*) DESC
    LIMIT 10
),
state_stats AS (
    SELECT 
        a.state,
        SUM(CASE WHEN aggressive = 0 THEN 1 ELSE 0 END) AS friendly,
        SUM(CASE WHEN aggressive = 1 THEN 1 ELSE 0 END) AS hostile,
        AVG(age)                                         AS avg_age
    FROM alien_data AS a
    JOIN top_states  AS t 
      ON a.state = t.state
    GROUP BY a.state
)
SELECT COUNT(*) AS qualifying_state_count
FROM state_stats
WHERE friendly > hostile
  AND avg_age > 200;