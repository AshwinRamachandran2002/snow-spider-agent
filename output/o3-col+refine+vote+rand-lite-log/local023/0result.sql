SELECT pl.player_name,
       ROUND(1.0 * r.total_runs / p.matches_played, 4) AS batting_average
FROM (
    SELECT b.striker AS player_id,
           SUM(s.runs_scored) AS total_runs
    FROM ball_by_ball AS b
    JOIN batsman_scored AS s
      ON s.match_id   = b.match_id
     AND s.over_id    = b.over_id
     AND s.ball_id    = b.ball_id
     AND s.innings_no = b.innings_no
    JOIN match AS m
      ON m.match_id = b.match_id
    WHERE m.season_id = 5
    GROUP BY b.striker
) AS r
JOIN (
    SELECT b.striker AS player_id,
           COUNT(DISTINCT b.match_id) AS matches_played
    FROM ball_by_ball AS b
    JOIN match AS m
      ON m.match_id = b.match_id
    WHERE m.season_id = 5
    GROUP BY b.striker
) AS p
  ON r.player_id = p.player_id
JOIN player AS pl
  ON pl.player_id = r.player_id
ORDER BY batting_average DESC
LIMIT 5;