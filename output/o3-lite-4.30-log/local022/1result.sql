SELECT DISTINCT p.player_name
FROM (
    SELECT b.match_id,
           b.striker AS player_id,
           SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball b
    JOIN batsman_scored bs
      ON b.match_id   = bs.match_id
     AND b.over_id    = bs.over_id
     AND b.ball_id    = bs.ball_id
     AND b.innings_no = bs.innings_no
    GROUP BY b.match_id, b.striker
    HAVING SUM(bs.runs_scored) >= 100
) t
JOIN player_match pm
  ON pm.match_id  = t.match_id
 AND pm.player_id = t.player_id
JOIN match m
  ON m.match_id = t.match_id
JOIN player p
  ON p.player_id = t.player_id
WHERE m.match_winner IS NOT NULL
  AND pm.team_id <> m.match_winner
ORDER BY p.player_name;