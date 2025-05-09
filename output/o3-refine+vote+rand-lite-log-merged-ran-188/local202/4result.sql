WITH state_totals AS (
    SELECT
        LOWER(state) AS state,
        COUNT(*) AS total_population
    FROM alien_data
    GROUP BY LOWER(state)
),
top10 AS (
    SELECT state
    FROM state_totals
    ORDER BY total_population DESC, state
    LIMIT 10
),
state_stats AS (
    SELECT
        LOWER(ad.state) AS state,
        SUM(CASE WHEN ad.aggressive = 0 THEN 1 ELSE 0 END) AS friendly_count,
        SUM(CASE WHEN ad.aggressive = 1 THEN 1 ELSE 0 END) AS hostile_count,
        AVG(ad.age) AS avg_age
    FROM alien_data ad
    JOIN top10 t ON LOWER(ad.state) = t.state
    GROUP BY LOWER(ad.state)
),
qualified_states AS (
    SELECT state
    FROM state_stats
    WHERE friendly_count > hostile_count
      AND avg_age > 200
)
SELECT COUNT(*) AS qualifying_state_count
FROM qualified_states;