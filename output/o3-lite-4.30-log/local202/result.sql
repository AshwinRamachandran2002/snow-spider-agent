WITH top_states AS (
    SELECT LOWER("state") AS state
    FROM "alien_data"
    GROUP BY LOWER("state")
    ORDER BY COUNT(*) DESC, LOWER("state")
    LIMIT 10
),
state_stats AS (
    SELECT 
        ts.state,
        SUM(CASE WHEN ad."aggressive" = 0 THEN 1 ELSE 0 END) AS friendly_cnt,
        SUM(CASE WHEN ad."aggressive" = 1 THEN 1 ELSE 0 END) AS hostile_cnt,
        AVG(ad."age")                                        AS avg_age
    FROM top_states ts
    JOIN "alien_data" ad
      ON LOWER(ad."state") = ts.state
    GROUP BY ts.state
)
SELECT COUNT(*) AS num_states
FROM state_stats
WHERE friendly_cnt > hostile_cnt
  AND avg_age > 200;