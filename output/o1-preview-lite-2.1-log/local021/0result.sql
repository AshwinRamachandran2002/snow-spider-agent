SELECT ROUND(AVG(avg_runs_per_match), 4) AS Average_Total_Score
FROM (
  SELECT pm.striker, AVG(pm.total_runs) AS avg_runs_per_match
  FROM (
    SELECT b.match_id, b.striker, SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS b
    JOIN batsman_scored AS bs
      ON b.match_id = bs.match_id
      AND b.over_id = bs.over_id
      AND b.ball_id = bs.ball_id
      AND b.innings_no = bs.innings_no
    GROUP BY b.match_id, b.striker
  ) AS pm
  WHERE pm.striker IN (
    SELECT striker
    FROM (
      SELECT b.match_id, b.striker, SUM(bs.runs_scored) AS match_runs
      FROM ball_by_ball AS b
      JOIN batsman_scored AS bs
        ON b.match_id = bs.match_id
        AND b.over_id = bs.over_id
        AND b.ball_id = bs.ball_id
        AND b.innings_no = bs.innings_no
      GROUP BY b.match_id, b.striker
      HAVING SUM(bs.runs_scored) > 50
    )
  )
  GROUP BY pm.striker
) AS avg_scores;