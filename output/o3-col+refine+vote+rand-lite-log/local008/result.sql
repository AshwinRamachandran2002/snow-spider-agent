WITH career_totals AS (
    SELECT 
        player_id,
        SUM(g)  AS total_games,
        SUM(r)  AS total_runs,
        SUM(h)  AS total_hits,
        SUM(hr) AS total_hr
    FROM batting
    GROUP BY player_id
),
max_vals AS (
    SELECT
        MAX(total_games) AS max_games,
        MAX(total_runs)  AS max_runs,
        MAX(total_hits)  AS max_hits,
        MAX(total_hr)    AS max_hr
    FROM career_totals
)
SELECT 'Games Played' AS metric,
       p.name_given   AS player_given_name,
       c.total_games  AS record_value
FROM career_totals c
JOIN player      p ON p.player_id = c.player_id
JOIN max_vals    m ON c.total_games = m.max_games

UNION ALL
SELECT 'Runs',
       p.name_given,
       c.total_runs
FROM career_totals c
JOIN player      p ON p.player_id = c.player_id
JOIN max_vals    m ON c.total_runs = m.max_runs

UNION ALL
SELECT 'Hits',
       p.name_given,
       c.total_hits
FROM career_totals c
JOIN player      p ON p.player_id = c.player_id
JOIN max_vals    m ON c.total_hits = m.max_hits

UNION ALL
SELECT 'Home Runs',
       p.name_given,
       c.total_hr
FROM career_totals c
JOIN player      p ON p.player_id = c.player_id
JOIN max_vals    m ON c.total_hr = m.max_hr;