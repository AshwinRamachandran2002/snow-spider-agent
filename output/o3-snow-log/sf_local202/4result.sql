WITH state_stats AS (
    SELECT
        "state",
        COUNT(*)                                                  AS total_aliens,
        SUM(CASE WHEN "aggressive" = 0 THEN 1 ELSE 0 END)        AS friendly_cnt,
        SUM(CASE WHEN "aggressive" = 1 THEN 1 ELSE 0 END)        AS hostile_cnt,
        AVG("age")                                               AS avg_age
    FROM CITY_LEGISLATION.CITY_LEGISLATION.ALIEN_DATA
    WHERE "state" IS NOT NULL
    GROUP BY "state"
),
top_states AS (
    SELECT *
    FROM state_stats
    ORDER BY total_aliens DESC NULLS LAST
    LIMIT 10
),
qualified_states AS (
    SELECT *
    FROM top_states
    WHERE avg_age > 200
      AND friendly_cnt > hostile_cnt
)
SELECT COUNT(*) AS friendly_states_count
FROM qualified_states;