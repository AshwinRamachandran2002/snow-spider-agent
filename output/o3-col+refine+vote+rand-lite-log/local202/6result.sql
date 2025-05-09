SELECT COUNT(*) AS num_states
FROM (
    SELECT 
        "state",
        COUNT(*) AS total_aliens,
        SUM(CASE WHEN "aggressive" = 0 THEN 1 ELSE 0 END) AS friendly,
        SUM(CASE WHEN "aggressive" = 1 THEN 1 ELSE 0 END) AS hostile,
        AVG("age") AS avg_age
    FROM "alien_data"
    GROUP BY "state"
    ORDER BY total_aliens DESC
    LIMIT 10
) AS top_states
WHERE friendly > hostile        -- higher percentage of friendly than hostile
  AND avg_age > 200;            -- average age exceeds 200