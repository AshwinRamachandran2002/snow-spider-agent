WITH totals AS (
    SELECT
        b.player_id,
        SUM(COALESCE(NULLIF(b.g ,''),0))   AS games_played,
        SUM(COALESCE(NULLIF(b.r ,''),0))   AS runs,
        SUM(COALESCE(NULLIF(b.h ,''),0))   AS hits,
        SUM(COALESCE(NULLIF(b.hr,''),0))   AS home_runs
    FROM batting AS b
    GROUP BY b.player_id
),
max_vals AS (
    SELECT
        MAX(games_played) AS max_games,
        MAX(runs)         AS max_runs,
        MAX(hits)         AS max_hits,
        MAX(home_runs)    AS max_hr
    FROM totals
)
SELECT 'Games Played' AS metric,
       p.name_given    AS player_given_name,
       t.games_played  AS value
FROM totals t
JOIN max_vals mv ON t.games_played = mv.max_games
JOIN player   p  ON p.player_id   = t.player_id

UNION ALL
SELECT 'Runs',
       p.name_given,
       t.runs
FROM totals t
JOIN max_vals mv ON t.runs = mv.max_runs
JOIN player   p  ON p.player_id = t.player_id

UNION ALL
SELECT 'Hits',
       p.name_given,
       t.hits
FROM totals t
JOIN max_vals mv ON t.hits = mv.max_hits
JOIN player   p  ON p.player_id = t.player_id

UNION ALL
SELECT 'Home Runs',
       p.name_given,
       t.home_runs
FROM totals t
JOIN max_vals mv ON t.home_runs = mv.max_hr
JOIN player   p  ON p.player_id = t.player_id

ORDER BY metric;