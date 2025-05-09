WITH total_games AS (
    SELECT player_id, SUM(g) AS total_games
    FROM batting
    GROUP BY player_id
),
max_games AS (
    SELECT MAX(total_games) AS max_total_games FROM total_games
),
games_leader AS (
    SELECT 'Games played' AS stat_name, p.name_given AS player_name, total_games AS score, 1 AS sort_order
    FROM total_games tg
    JOIN player p ON tg.player_id = p.player_id
    WHERE tg.total_games = (SELECT max_total_games FROM max_games)
),
total_runs AS (
    SELECT player_id, SUM(r) AS total_runs
    FROM batting
    GROUP BY player_id
),
max_runs AS (
    SELECT MAX(total_runs) AS max_total_runs FROM total_runs
),
runs_leader AS (
    SELECT 'Runs' AS stat_name, p.name_given AS player_name, total_runs AS score, 2 AS sort_order
    FROM total_runs tr
    JOIN player p ON tr.player_id = p.player_id
    WHERE tr.total_runs = (SELECT max_total_runs FROM max_runs)
),
total_hits AS (
    SELECT player_id, SUM(h) AS total_hits
    FROM batting
    GROUP BY player_id
),
max_hits AS (
    SELECT MAX(total_hits) AS max_total_hits FROM total_hits
),
hits_leader AS (
    SELECT 'Hits' AS stat_name, p.name_given AS player_name, total_hits AS score, 3 AS sort_order
    FROM total_hits th
    JOIN player p ON th.player_id = p.player_id
    WHERE th.total_hits = (SELECT max_total_hits FROM max_hits)
),
total_home_runs AS (
    SELECT player_id, SUM(hr) AS total_home_runs
    FROM batting
    GROUP BY player_id
),
max_home_runs AS (
    SELECT MAX(total_home_runs) AS max_total_home_runs FROM total_home_runs
),
home_runs_leader AS (
    SELECT 'Home runs' AS stat_name, p.name_given AS player_name, total_home_runs AS score, 4 AS sort_order
    FROM total_home_runs thr
    JOIN player p ON thr.player_id = p.player_id
    WHERE thr.total_home_runs = (SELECT max_total_home_runs FROM max_home_runs)
)

SELECT stat_name, player_name, ROUND(score, 4) AS score
FROM (
    SELECT * FROM games_leader
    UNION ALL
    SELECT * FROM runs_leader
    UNION ALL
    SELECT * FROM hits_leader
    UNION ALL
    SELECT * FROM home_runs_leader
) AS stats
ORDER BY sort_order;