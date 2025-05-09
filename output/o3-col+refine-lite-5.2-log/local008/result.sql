WITH totals AS (
    SELECT 
        player_id,
        SUM(g)  AS total_games,
        SUM(r)  AS total_runs,
        SUM(h)  AS total_hits,
        SUM(hr) AS total_hr
    FROM batting
    GROUP BY player_id
), max_vals AS (
    SELECT 
        MAX(total_games) AS max_games,
        MAX(total_runs)  AS max_runs,
        MAX(total_hits)  AS max_hits,
        MAX(total_hr)    AS max_hr
    FROM totals
)
SELECT
    p.name_given,
    CASE WHEN t.total_games = m.max_games THEN t.total_games END AS games_played,
    CASE WHEN t.total_runs  = m.max_runs  THEN t.total_runs  END AS runs,
    CASE WHEN t.total_hits  = m.max_hits  THEN t.total_hits  END AS hits,
    CASE WHEN t.total_hr    = m.max_hr    THEN t.total_hr    END AS home_runs
FROM totals AS t
JOIN max_vals AS m
JOIN player  AS p ON p.player_id = t.player_id
WHERE t.total_games = m.max_games
   OR t.total_runs  = m.max_runs
   OR t.total_hits  = m.max_hits
   OR t.total_hr    = m.max_hr
ORDER BY p.name_given;