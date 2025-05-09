WITH batting_clean AS (
    SELECT
        player_id,
        CAST(COALESCE(NULLIF(g ,''),0) AS INTEGER)  AS g,
        CAST(COALESCE(NULLIF(r ,''),0) AS INTEGER)  AS r,
        CAST(COALESCE(NULLIF(h ,''),0) AS INTEGER)  AS h,
        CAST(COALESCE(NULLIF(hr,''),0) AS INTEGER)  AS hr
    FROM batting
),
career AS (
    SELECT
        player_id,
        SUM(g)  AS games,
        SUM(r)  AS runs,
        SUM(h)  AS hits,
        SUM(hr) AS home_runs
    FROM batting_clean
    GROUP BY player_id
),
maxvals AS (
    SELECT
        MAX(games)      AS max_games,
        MAX(runs)       AS max_runs,
        MAX(hits)       AS max_hits,
        MAX(home_runs)  AS max_home_runs
    FROM career
)
SELECT p.name_given                 AS player_given_name,
       'Games Played'               AS category,
       c.games                      AS value
FROM career  c
JOIN maxvals m ON c.games = m.max_games
JOIN player  p ON p.player_id = c.player_id

UNION ALL
SELECT p.name_given,
       'Runs',
       c.runs
FROM career  c
JOIN maxvals m ON c.runs = m.max_runs
JOIN player  p ON p.player_id = c.player_id

UNION ALL
SELECT p.name_given,
       'Hits',
       c.hits
FROM career  c
JOIN maxvals m ON c.hits = m.max_hits
JOIN player  p ON p.player_id = c.player_id

UNION ALL
SELECT p.name_given,
       'Home Runs',
       c.home_runs
FROM career  c
JOIN maxvals m ON c.home_runs = m.max_home_runs
JOIN player  p ON p.player_id = c.player_id

ORDER BY category, player_given_name;