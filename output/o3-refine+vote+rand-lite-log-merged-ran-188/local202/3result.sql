WITH per_state AS (
    SELECT
        state,
        COUNT(*) AS total_aliens,
        SUM(CASE WHEN aggressive = 0 THEN 1 ELSE 0 END) AS friendly_aliens,
        SUM(CASE WHEN aggressive = 1 THEN 1 ELSE 0 END) AS hostile_aliens,
        AVG(age) AS avg_age
    FROM alien_data
    GROUP BY state
),
top_states AS (
    SELECT *
    FROM per_state
    ORDER BY total_aliens DESC, state
    LIMIT 10
)
SELECT COUNT(*) AS num_states_meeting_criteria
FROM top_states
WHERE friendly_aliens > hostile_aliens
  AND avg_age > 200;