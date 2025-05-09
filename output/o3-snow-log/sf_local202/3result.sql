WITH state_pop AS (   -- total aliens per state
    SELECT
        "state",
        COUNT(*) AS total_aliens
    FROM CITY_LEGISLATION.CITY_LEGISLATION.ALIEN_DATA
    GROUP BY "state"
),
top10_states AS (     -- 10 states with the largest alien populations
    SELECT
        "state"
    FROM state_pop
    ORDER BY total_aliens DESC NULLS LAST
    LIMIT 10
),
state_metrics AS (    -- friendly vs hostile counts and average age for those 10 states
    SELECT
        ad."state",
        AVG(ad."age")                                                  AS avg_age,
        SUM(CASE WHEN ad."aggressive" = 0 THEN 1 ELSE 0 END)           AS friendly_cnt,
        SUM(CASE WHEN ad."aggressive" = 1 THEN 1 ELSE 0 END)           AS hostile_cnt
    FROM CITY_LEGISLATION.CITY_LEGISLATION.ALIEN_DATA ad
    JOIN top10_states t
      ON ad."state" = t."state"
    GROUP BY ad."state"
)
SELECT
    COUNT(*) AS states_meeting_criteria   -- final answer
FROM state_metrics
WHERE friendly_cnt > hostile_cnt          -- more friendly than hostile
  AND avg_age > 200;                      -- average age exceeds 200