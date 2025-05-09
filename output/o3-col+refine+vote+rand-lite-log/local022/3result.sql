SELECT DISTINCT
       p.player_name
FROM (
    SELECT  b.match_id,
            b.striker AS player_id,
            SUM(s.runs_scored) AS total_runs
    FROM   ball_by_ball   AS b
    JOIN   batsman_scored AS s
           ON  b.match_id   = s.match_id
           AND b.over_id    = s.over_id
           AND b.ball_id    = s.ball_id
           AND b.innings_no = s.innings_no
    GROUP BY b.match_id, b.striker
    HAVING  SUM(s.runs_scored) >= 100
) AS x
JOIN player_match pm  ON pm.match_id = x.match_id
                     AND pm.player_id = x.player_id
JOIN match        m   ON m.match_id  = x.match_id
JOIN player       p   ON p.player_id = x.player_id
WHERE pm.team_id <> m.match_winner;