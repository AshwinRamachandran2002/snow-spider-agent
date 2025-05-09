WITH striker_match_totals AS (
    SELECT 
        bbb.striker  AS player_id,
        bbb.match_id,
        SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS bbb
    JOIN batsman_scored AS bs
      ON  bbb.match_id = bs.match_id
      AND bbb.over_id  = bs.over_id
      AND bbb.ball_id  = bs.ball_id
    GROUP BY bbb.striker, bbb.match_id
    HAVING total_runs > 50          -- keep only scores greater than 50
)
SELECT ROUND(AVG(total_runs), 4) AS average_total_runs_above_50
FROM   striker_match_totals;