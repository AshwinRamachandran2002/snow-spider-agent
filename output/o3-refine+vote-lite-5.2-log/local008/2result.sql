WITH career_totals AS (
    SELECT
        player_id,
        SUM(g)  AS games_played,
        SUM(r)  AS runs_scored,
        SUM(h)  AS hits_made,
        SUM(hr) AS home_runs
    FROM batting
    GROUP BY player_id
),
max_values AS (
    SELECT
        MAX(games_played) AS max_games,
        MAX(runs_scored)  AS max_runs,
        MAX(hits_made)    AS max_hits,
        MAX(home_runs)    AS max_hrs
    FROM career_totals
)
SELECT 'Games Played' AS stat,
       pl.name_given   AS player_given_name,
       ct.games_played AS value
FROM career_totals ct
JOIN max_values mv ON ct.games_played = mv.max_games
JOIN player pl      ON pl.player_id   = ct.player_id

UNION ALL

SELECT 'Runs'        AS stat,
       pl.name_given AS player_given_name,
       ct.runs_scored AS value
FROM career_totals ct
JOIN max_values mv ON ct.runs_scored = mv.max_runs
JOIN player pl      ON pl.player_id  = ct.player_id

UNION ALL

SELECT 'Hits'        AS stat,
       pl.name_given AS player_given_name,
       ct.hits_made  AS value
FROM career_totals ct
JOIN max_values mv ON ct.hits_made = mv.max_hits
JOIN player pl      ON pl.player_id = ct.player_id

UNION ALL

SELECT 'Home Runs'   AS stat,
       pl.name_given AS player_given_name,
       ct.home_runs  AS value
FROM career_totals ct
JOIN max_values mv ON ct.home_runs = mv.max_hrs
JOIN player pl      ON pl.player_id = ct.player_id
ORDER BY stat;