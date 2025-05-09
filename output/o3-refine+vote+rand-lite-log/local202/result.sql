WITH state_totals AS (
    SELECT
        state,
        COUNT(*)                                         AS total_aliens,
        SUM(CASE WHEN aggressive = 0 THEN 1 ELSE 0 END) AS friendly_aliens,
        SUM(CASE WHEN aggressive = 1 THEN 1 ELSE 0 END) AS hostile_aliens,
        AVG(age)                                         AS avg_age
    FROM alien_data
    WHERE state IS NOT NULL
    GROUP BY state
),
top_10_states AS (
    SELECT state
    FROM state_totals
    ORDER BY total_aliens DESC, state
    LIMIT 10
),
qualified_states AS (
    SELECT
        st.state
    FROM state_totals st
    JOIN top_10_states t
      ON st.state = t.state
    WHERE
        (1.0 * friendly_aliens / total_aliens) > (1.0 * hostile_aliens / total_aliens)
        AND avg_age > 200
)
SELECT COUNT(*) AS num_states
FROM qualified_states;