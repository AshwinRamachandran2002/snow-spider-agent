WITH match_s5 AS (
    SELECT match_id
    FROM match
    WHERE season_id = 5
),
player_runs AS (
    SELECT 
        bb.striker AS player_id,
        SUM(bs.runs_scored) AS total_runs
    FROM batsman_scored bs
    JOIN ball_by_ball bb 
         ON bb.match_id = bs.match_id
        AND bb.over_id  = bs.over_id
        AND bb.ball_id  = bs.ball_id
        AND bb.innings_no = bs.innings_no
    JOIN match_s5 ms 
         ON ms.match_id = bs.match_id
    GROUP BY bb.striker
),
player_matches AS (
    SELECT 
        pm.player_id,
        COUNT(DISTINCT pm.match_id) AS matches_played
    FROM player_match pm
    JOIN match_s5 ms 
         ON ms.match_id = pm.match_id
    GROUP BY pm.player_id
)
SELECT 
    p.player_name,
    ROUND(CAST(pr.total_runs AS REAL) / pm.matches_played, 4) AS batting_average
FROM player_runs     pr
JOIN player_matches  pm ON pr.player_id = pm.player_id
JOIN player          p  ON p.player_id  = pr.player_id
WHERE pm.matches_played > 0
ORDER BY batting_average DESC, p.player_name
LIMIT 5;