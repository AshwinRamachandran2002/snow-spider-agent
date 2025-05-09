WITH batting_totals AS (
    SELECT
        player_id,
        SUM(CASE WHEN g  IS NULL OR g  = '' THEN 0 ELSE CAST(g  AS INTEGER) END) AS games_played,
        SUM(CASE WHEN r  IS NULL OR r  = '' THEN 0 ELSE CAST(r  AS INTEGER) END) AS runs,
        SUM(CASE WHEN h  IS NULL OR h  = '' THEN 0 ELSE CAST(h  AS INTEGER) END) AS hits,
        SUM(CASE WHEN hr IS NULL OR hr = '' THEN 0 ELSE CAST(hr AS INTEGER) END) AS home_runs
    FROM batting
    GROUP BY player_id
),
max_values AS (
    SELECT
        MAX(games_played) AS max_games,
        MAX(runs)         AS max_runs,
        MAX(hits)         AS max_hits,
        MAX(home_runs)    AS max_hr
    FROM batting_totals
),
leaders AS (
    SELECT player_id, 'Games Played' AS metric, games_played AS value
    FROM batting_totals, max_values
    WHERE games_played = max_games
    
    UNION ALL
    
    SELECT player_id, 'Runs' AS metric, runs
    FROM batting_totals, max_values
    WHERE runs = max_runs
    
    UNION ALL
    
    SELECT player_id, 'Hits' AS metric, hits
    FROM batting_totals, max_values
    WHERE hits = max_hits
    
    UNION ALL
    
    SELECT player_id, 'Home Runs' AS metric, home_runs
    FROM batting_totals, max_values
    WHERE home_runs = max_hr
)
SELECT
    p.name_given,
    l.metric,
    l.value
FROM leaders l
JOIN player p
  ON p.player_id = l.player_id
ORDER BY l.metric, p.name_given;