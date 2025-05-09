WITH per_bowler_match AS (
  SELECT
    b.bowler,
    p.player_name,
    b.match_id,
    COUNT(*) AS balls_bowled_in_match,
    SUM(bs.runs_scored) AS runs_conceded_in_match,
    COUNT(CASE WHEN w.player_out IS NOT NULL THEN 1 END) AS wickets_in_match
  FROM ball_by_ball b
  JOIN batsman_scored bs
    ON b.match_id = bs.match_id
    AND b.over_id = bs.over_id
    AND b.ball_id = bs.ball_id
    AND b.innings_no = bs.innings_no
  LEFT JOIN wicket_taken w
    ON b.match_id = w.match_id
    AND b.over_id = w.over_id
    AND b.ball_id = w.ball_id
    AND b.innings_no = w.innings_no
  JOIN player p
    ON b.bowler = p.player_id
  GROUP BY b.bowler, b.match_id
),
best_performance AS (
  SELECT
    bowler,
    player_name,
    wickets_in_match,
    runs_conceded_in_match,
    wickets_in_match || '-' || runs_conceded_in_match AS best_performance,
    RANK() OVER (
      PARTITION BY bowler
      ORDER BY wickets_in_match DESC, runs_conceded_in_match ASC
    ) AS rnk
  FROM per_bowler_match
),
best_performance_final AS (
  SELECT
    bowler,
    player_name,
    best_performance
  FROM best_performance
  WHERE rnk = 1
),
total_stats AS (
  SELECT
    b.bowler,
    p.player_name,
    COUNT(*) AS total_balls,
    SUM(bs.runs_scored) AS total_runs_conceded,
    COUNT(CASE WHEN w.player_out IS NOT NULL THEN 1 END) AS total_wickets
  FROM ball_by_ball b
  JOIN batsman_scored bs
    ON b.match_id = bs.match_id
    AND b.over_id = bs.over_id
    AND b.ball_id = bs.ball_id
    AND b.innings_no = bs.innings_no
  LEFT JOIN wicket_taken w
    ON b.match_id = w.match_id
    AND b.over_id = w.over_id
    AND b.ball_id = w.ball_id
    AND b.innings_no = w.innings_no
  JOIN player p
    ON b.bowler = p.player_id
  GROUP BY b.bowler
)
SELECT
  t.player_name AS bowler_name,
  t.total_wickets,
  ROUND((t.total_runs_conceded * 6.0) / t.total_balls, 4) AS economy_rate,
  CASE
    WHEN t.total_wickets > 0 THEN ROUND(t.total_balls * 1.0 / t.total_wickets, 4)
    ELSE NULL
  END AS strike_rate,
  bpf.best_performance
FROM total_stats t
JOIN best_performance_final bpf
  ON t.bowler = bpf.bowler
ORDER BY t.player_name;