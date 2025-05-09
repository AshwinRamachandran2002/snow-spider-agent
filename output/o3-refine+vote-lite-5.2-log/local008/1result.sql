WITH career_stats AS (
    SELECT
        player_id,
        SUM(COALESCE(g,0))    AS games,
        SUM(COALESCE(r,0))    AS runs,
        SUM(COALESCE(h,0))    AS hits,
        SUM(COALESCE(hr,0))   AS home_runs
    FROM batting
    GROUP BY player_id
),
max_vals AS (
    SELECT
        MAX(games)       AS max_games,
        MAX(runs)        AS max_runs,
        MAX(hits)        AS max_hits,
        MAX(home_runs)   AS max_home_runs
    FROM career_stats
)
SELECT p.name_given        AS given_name,
       'Games Played'      AS category,
       cs.games            AS value
FROM career_stats cs
JOIN max_vals mv  ON cs.games = mv.max_games
JOIN player  p    ON p.player_id = cs.player_id

UNION ALL
SELECT p.name_given,
       'Runs',
       cs.runs
FROM career_stats cs
JOIN max_vals mv  ON cs.runs = mv.max_runs
JOIN player  p    ON p.player_id = cs.player_id

UNION ALL
SELECT p.name_given,
       'Hits',
       cs.hits
FROM career_stats cs
JOIN max_vals mv  ON cs.hits = mv.max_hits
JOIN player  p    ON p.player_id = cs.player_id

UNION ALL
SELECT p.name_given,
       'Home Runs',
       cs.home_runs
FROM career_stats cs
JOIN max_vals mv  ON cs.home_runs = mv.max_home_runs
JOIN player  p    ON p.player_id = cs.player_id

ORDER BY category, given_name;