WITH state_stats AS (
    SELECT
        "state",
        COUNT(*)                                                  AS "total_aliens",
        SUM(CASE WHEN "aggressive" = 0 THEN 1 ELSE 0 END)        AS "friendly_aliens",
        SUM(CASE WHEN "aggressive" = 1 THEN 1 ELSE 0 END)        AS "hostile_aliens",
        AVG("age")                                                AS "avg_age"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.ALIEN_DATA
    GROUP BY "state"
),
top_10_states AS (
    SELECT *
    FROM state_stats
    ORDER BY "total_aliens" DESC NULLS LAST
    LIMIT 10
),
qualified_states AS (
    SELECT *
    FROM top_10_states
    WHERE "friendly_aliens" > "hostile_aliens"      -- higher % friendly than hostile
      AND "avg_age" > 200                           -- average age exceeds 200
)
SELECT COUNT(*) AS "num_states"
FROM qualified_states;