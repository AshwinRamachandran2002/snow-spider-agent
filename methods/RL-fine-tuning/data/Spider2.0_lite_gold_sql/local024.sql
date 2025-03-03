SELECT tr.country_name AS Country,
       ROUND(tr.total_runs * 1.0 / mp.matches_played, 4) AS Average_Runs_per_Match,
       ROUND(CASE WHEN t_out.times_out = 0 THEN NULL ELSE tr.total_runs * 1.0 / t_out.times_out END, 4) AS Batting_Average
FROM (
    SELECT p.country_name, SUM(bs.runs_scored) AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS bbb
      ON bs.match_id = bbb.match_id
     AND bs.over_id = bbb.over_id
     AND bs.ball_id = bbb.ball_id
     AND bs.innings_no = bbb.innings_no
    JOIN player AS p
      ON bbb.striker = p.player_id
    GROUP BY p.country_name
) AS tr
JOIN (
    SELECT p.country_name, COUNT(wt.player_out) AS times_out
    FROM wicket_taken AS wt
    JOIN player AS p
      ON wt.player_out = p.player_id
    GROUP BY p.country_name
) AS t_out
  ON tr.country_name = t_out.country_name
JOIN (
    SELECT p.country_name, COUNT(DISTINCT pm.match_id) AS matches_played
    FROM player_match AS pm
    JOIN player AS p
      ON pm.player_id = p.player_id
    GROUP BY p.country_name
) AS mp
  ON tr.country_name = mp.country_name
ORDER BY Average_Runs_per_Match DESC
LIMIT 5;