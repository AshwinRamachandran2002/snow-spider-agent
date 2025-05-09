WITH state_stats AS (
    SELECT 
        "state",
        COUNT(*)                                                    AS total_aliens,
        SUM(CASE WHEN "aggressive" = 0 THEN 1 ELSE 0 END)           AS friendly_aliens,
        SUM(CASE WHEN "aggressive" = 1 THEN 1 ELSE 0 END)           AS hostile_aliens,
        AVG("age")                                                  AS avg_age
    FROM CITY_LEGISLATION.CITY_LEGISLATION.ALIEN_DATA
    WHERE "state" IS NOT NULL
    GROUP BY "state"
), ranked_states AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_aliens DESC) AS state_rank
    FROM state_stats
), filtered_states AS (
    SELECT 
        *
    FROM ranked_states
    WHERE state_rank <= 10                          -- top 10 states by alien population
      AND friendly_aliens > hostile_aliens          -- higher % friendly than hostile
      AND avg_age > 200                             -- average age exceeds 200
)
SELECT COUNT(*) AS num_states
FROM filtered_states;