SELECT ROUND(AVG(total_runs), 4) AS average_runs
FROM (
    SELECT 
        bb.match_id,
        bb.striker      AS player_id,
        SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS bb
    JOIN batsman_scored AS bs
         ON bb.match_id  = bs.match_id
        AND bb.over_id   = bs.over_id
        AND bb.ball_id   = bs.ball_id
        AND bb.innings_no = bs.innings_no
    GROUP BY bb.match_id, bb.striker
    HAVING SUM(bs.runs_scored) > 50
) AS per_player_match;