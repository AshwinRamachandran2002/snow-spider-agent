WITH totals AS (
    SELECT
        player_id,
        SUM(g)  AS games_played,
        SUM(r)  AS runs_scored,
        SUM(h)  AS hits_made,
        SUM(hr) AS home_runs
    FROM batting
    GROUP BY player_id
),
leaders AS (
    SELECT 'Games Played' AS category, player_id, games_played AS score
    FROM totals
    WHERE games_played = (SELECT MAX(games_played) FROM totals)
    
    UNION ALL
    
    SELECT 'Runs' AS category, player_id, runs_scored AS score
    FROM totals
    WHERE runs_scored = (SELECT MAX(runs_scored) FROM totals)
    
    UNION ALL
    
    SELECT 'Hits' AS category, player_id, hits_made AS score
    FROM totals
    WHERE hits_made = (SELECT MAX(hits_made) FROM totals)
    
    UNION ALL
    
    SELECT 'Home Runs' AS category, player_id, home_runs AS score
    FROM totals
    WHERE home_runs = (SELECT MAX(home_runs) FROM totals)
)
SELECT
    l.category,
    p.name_given,
    l.score
FROM leaders l
JOIN player p ON p.player_id = l.player_id
ORDER BY l.category;