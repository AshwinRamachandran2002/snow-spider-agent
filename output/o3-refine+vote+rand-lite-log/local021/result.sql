WITH per_player_match AS (
    SELECT 
        bb.match_id,
        bb.striker AS player_id,
        SUM(bs.runs_scored) AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS bb
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    GROUP BY bb.match_id, bb.striker
),
qualified_scores AS (
    SELECT total_runs
    FROM   per_player_match
    WHERE  total_runs > 50          -- only scores greater than 50
)
SELECT ROUND(AVG(total_runs), 4) AS average_runs_over_50
FROM   qualified_scores;