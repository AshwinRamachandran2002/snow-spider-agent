WITH state_stats AS (
    SELECT
        state,
        COUNT(*) AS total_aliens,
        SUM(CASE WHEN aggressive = 0 THEN 1 ELSE 0 END) AS friendly,
        SUM(CASE WHEN aggressive = 1 THEN 1 ELSE 0 END) AS hostile,
        AVG(age) AS avg_age
    FROM alien_data
    GROUP BY state
),
top10 AS (
    SELECT *
    FROM state_stats
    ORDER BY total_aliens DESC
    LIMIT 10
)
SELECT COUNT(*) AS qualifying_states
FROM top10
WHERE friendly > hostile
  AND avg_age > 200;