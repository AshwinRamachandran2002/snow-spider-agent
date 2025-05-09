WITH STATE_STATS AS (
    SELECT
        "state",
        COUNT(*) AS total_aliens,
        SUM(CASE WHEN "aggressive" = 0 THEN 1 ELSE 0 END) AS friendly_aliens,
        SUM(CASE WHEN "aggressive" = 1 THEN 1 ELSE 0 END) AS hostile_aliens,
        AVG("age") AS avg_age
    FROM CITY_LEGISLATION.CITY_LEGISLATION.ALIEN_DATA
    GROUP BY "state"
),
TOP_10_STATES AS (
    SELECT *
    FROM STATE_STATS
    ORDER BY total_aliens DESC NULLS LAST
    LIMIT 10
),
QUALIFIED_STATES AS (
    SELECT *
    FROM TOP_10_STATES
    WHERE friendly_aliens > hostile_aliens
      AND avg_age > 200
)
SELECT COUNT(*) AS number_of_states
FROM QUALIFIED_STATES;