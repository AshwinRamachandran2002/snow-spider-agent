WITH top_states AS (
    -- 1. Identify the 10 states with the largest alien populations
    SELECT "state"
    FROM "alien_data"
    GROUP BY "state"
    ORDER BY COUNT(*) DESC
    LIMIT 10
),
state_stats AS (
    -- 2. For those states, calculate friendly vs hostile counts and average age
    SELECT
        "state",
        SUM(CASE WHEN "aggressive" = 0 THEN 1 ELSE 0 END) AS friendly_aliens,
        SUM(CASE WHEN "aggressive" = 1 THEN 1 ELSE 0 END) AS hostile_aliens,
        AVG("age") AS avg_age
    FROM "alien_data"
    WHERE "state" IN (SELECT "state" FROM top_states)
    GROUP BY "state"
),
qualifying_states AS (
    -- 3. Keep only states where friendly aliens outnumber hostile ones
    --    AND the average age is greater than 200
    SELECT *
    FROM state_stats
    WHERE friendly_aliens > hostile_aliens
      AND avg_age > 200
)
-- 4. Count how many states meet both criteria
SELECT COUNT(*) AS qualifying_state_count
FROM qualifying_states;