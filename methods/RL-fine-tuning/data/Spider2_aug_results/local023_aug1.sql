-- Task: Please find the names of the top 10 players with the highest total runs scored in season 5.

WITH runs_scored AS (
    SELECT 
        bb.striker AS player_id,
        bs.runs_scored AS runs
    FROM 
        ball_by_ball AS bb
    JOIN 
        batsman_scored AS bs ON bb.match_id = bs.match_id 
            AND bb.over_id = bs.over_id 
            AND bb.ball_id = bs.ball_id 
            AND bb.innings_no = bs.innings_no
    WHERE 
        bb.match_id IN (SELECT match_id FROM match WHERE season_id = 5)
)
SELECT 
    p.player_name,
    SUM(r.runs) AS total_runs 
FROM 
    runs_scored AS r
JOIN
    player AS p ON r.player_id = p.player_id
GROUP BY 
    r.player_id
ORDER BY 
    total_runs DESC
LIMIT 10;