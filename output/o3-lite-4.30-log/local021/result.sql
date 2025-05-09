SELECT ROUND(AVG(total_runs), 4) AS average_total_runs
FROM (
    SELECT 
        b.match_id,
        b.striker,
        SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS b
    JOIN batsman_scored AS bs
      ON b.match_id   = bs.match_id
     AND b.over_id    = bs.over_id
     AND b.ball_id    = bs.ball_id
     AND b.innings_no = bs.innings_no
    GROUP BY b.match_id, b.striker
    HAVING SUM(bs.runs_scored) > 50
);