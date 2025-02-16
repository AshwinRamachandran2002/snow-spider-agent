-- Task: Retrieve the names of players who scored no less than 100 runs in a match.
WITH player_runs AS (
    -- Calculate total runs scored by each player in each match
    SELECT 
        bbb.striker AS player_id, 
        bbb.match_id, 
        SUM(bsc.runs_scored) AS total_runs 
    FROM 
        ball_by_ball AS bbb
    JOIN 
        batsman_scored AS bsc
    ON 
        bbb.match_id = bsc.match_id 
        AND bbb.over_id = bsc.over_id 
        AND bbb.ball_id = bsc.ball_id 
        AND bbb.innings_no = bsc.innings_no
    GROUP BY 
        bbb.striker, bbb.match_id
    HAVING 
        SUM(bsc.runs_scored) >= 100
)
-- Select distinct player names who scored 100 or more runs in a match
SELECT DISTINCT 
    p.player_name 
FROM 
    player_runs AS pr
JOIN 
    player AS p
ON 
    pr.player_id = p.player_id
ORDER BY 
    p.player_name;