WITH state_stats AS (
    SELECT
        state,
        COUNT(*) AS total_aliens,
        SUM(CASE WHEN aggressive = 0 THEN 1 ELSE 0 END) AS friendly_count,
        SUM(CASE WHEN aggressive = 1 THEN 1 ELSE 0 END) AS hostile_count,
        AVG(age) AS avg_age
    FROM alien_data
    GROUP BY state
),
top_states AS (
    SELECT *
    FROM state_stats
    ORDER BY total_aliens DESC
    LIMIT 10
)
SELECT COUNT(*) AS states_meeting_criteria
FROM top_states
WHERE friendly_count > hostile_count
  AND avg_age > 200;