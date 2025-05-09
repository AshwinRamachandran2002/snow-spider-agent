WITH striker_runs AS (
    SELECT
        bb.striker          AS player_id,
        bb.match_id,
        SUM(bs.runs_scored) AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball  AS bb
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    GROUP BY bb.striker, bb.match_id
),
fifty_plus AS (
    SELECT total_runs
    FROM striker_runs
    WHERE total_runs > 50
)
SELECT ROUND(AVG(total_runs), 4) AS average_runs_over_50
FROM fifty_plus;