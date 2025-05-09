/* Players who hit at least 100 runs but were on the losing side */
SELECT DISTINCT
       p.player_name
FROM (
        /* runs scored per player per match */
        SELECT  bb.match_id,
                bb.striker AS player_id,
                SUM(bs.runs_scored) AS total_runs
        FROM    batsman_scored AS bs
        JOIN    ball_by_ball  AS bb
               ON  bb.match_id   = bs.match_id
               AND bb.over_id    = bs.over_id
               AND bb.ball_id    = bs.ball_id
               AND bb.innings_no = bs.innings_no
        GROUP BY bb.match_id,
                 bb.striker
        HAVING  SUM(bs.runs_scored) >= 100
     ) AS big_scores
JOIN player_match AS pm
  ON  pm.match_id  = big_scores.match_id
 AND pm.player_id = big_scores.player_id          -- team represented
JOIN match AS m
  ON  m.match_id = big_scores.match_id
JOIN player AS p
  ON  p.player_id = big_scores.player_id
WHERE m.match_winner IS NOT NULL                  -- result decided
  AND pm.team_id <> m.match_winner;               -- player's team lost