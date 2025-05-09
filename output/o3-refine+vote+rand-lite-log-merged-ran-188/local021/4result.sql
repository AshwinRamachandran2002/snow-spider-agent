SELECT ROUND(AVG(player_match_runs), 4) AS average_runs_above_50
FROM (
    /* total runs for every striker in every match */
    SELECT 
        bb.striker            AS player_id,
        bb.match_id,
        SUM(bs.runs_scored)   AS player_match_runs
    FROM ball_by_ball  AS bb
    JOIN batsman_scored AS bs
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    GROUP BY bb.striker, bb.match_id
    /* keep only those (player,match) pairs where the striker scored > 50 */
    HAVING SUM(bs.runs_scored) > 50
) t;