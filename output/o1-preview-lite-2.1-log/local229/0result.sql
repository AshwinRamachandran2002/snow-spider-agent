WITH ball_data AS (
  SELECT
    match_id,
    innings_no,
    over_id,
    ball_id,
    striker,
    non_striker,
    CASE WHEN striker < non_striker THEN striker ELSE non_striker END AS batter1,
    CASE WHEN striker > non_striker THEN striker ELSE non_striker END AS batter2
  FROM ball_by_ball
),
ball_with_prev AS (
  SELECT
    *,
    LAG(batter1) OVER(PARTITION BY match_id, innings_no ORDER BY over_id, ball_id) AS prev_batter1,
    LAG(batter2) OVER(PARTITION BY match_id, innings_no ORDER BY over_id, ball_id) AS prev_batter2
  FROM ball_data
),
ball_with_flag AS (
  SELECT
    *,
    CASE 
      WHEN prev_batter1 IS NULL THEN 0
      WHEN batter1 != prev_batter1 OR batter2 != prev_batter2 THEN 1
      ELSE 0
    END AS new_partnership_flag
  FROM ball_with_prev
),
ball_with_partnership_id AS (
  SELECT
    *,
    SUM(new_partnership_flag) OVER(PARTITION BY match_id, innings_no ORDER BY over_id, ball_id) AS partnership_id
  FROM ball_with_flag
),
ball_runs AS (
  SELECT
    bwp.match_id,
    bwp.innings_no,
    bwp.partnership_id,
    bwp.over_id,
    bwp.ball_id,
    bwp.striker,
    bwp.non_striker,
    bwp.batter1,
    bwp.batter2,
    COALESCE(bs.runs_scored, 0) AS runs_scored,
    COALESCE(er.extra_runs, 0) AS extra_runs
  FROM ball_with_partnership_id bwp
  LEFT JOIN batsman_scored bs
    ON bwp.match_id = bs.match_id AND bwp.innings_no = bs.innings_no AND bwp.over_id = bs.over_id AND bwp.ball_id = bs.ball_id
  LEFT JOIN extra_runs er
    ON bwp.match_id = er.match_id AND bwp.innings_no = er.innings_no AND bwp.over_id = er.over_id AND bwp.ball_id = er.ball_id
),
partnership_aggregate AS (
  SELECT
    br.match_id,
    br.partnership_id,
    br.batter1,
    br.batter2,
    SUM(br.runs_scored) AS total_batsman_runs,
    SUM(br.extra_runs) AS total_extra_runs,
    SUM(br.runs_scored) + SUM(br.extra_runs) AS partnership_runs
  FROM ball_runs br
  GROUP BY br.match_id, br.partnership_id, br.batter1, br.batter2
),
batter_runs AS (
  SELECT
    br.match_id,
    br.partnership_id,
    br.batsman_id,
    SUM(br.runs_scored) AS runs_scored
  FROM (
    SELECT match_id, partnership_id, striker AS batsman_id, runs_scored
    FROM ball_runs
    UNION ALL
    SELECT match_id, partnership_id, non_striker AS batsman_id, 0 AS runs_scored
    FROM ball_runs
  ) br
  GROUP BY br.match_id, br.partnership_id, br.batsman_id
),
partnership_runs AS (
  SELECT
    pa.match_id,
    pa.partnership_id,
    pa.batter1,
    pa.batter2,
    COALESCE(b1r.runs_scored, 0) AS batter1_runs,
    COALESCE(b2r.runs_scored, 0) AS batter2_runs,
    pa.partnership_runs
  FROM partnership_aggregate pa
  LEFT JOIN batter_runs b1r
    ON pa.match_id = b1r.match_id AND pa.partnership_id = b1r.partnership_id AND pa.batter1 = b1r.batsman_id
  LEFT JOIN batter_runs b2r
    ON pa.match_id = b2r.match_id AND pa.partnership_id = b2r.partnership_id AND pa.batter2 = b2r.batsman_id
),
max_partnership_per_match AS (
  SELECT
    match_id,
    MAX(partnership_runs) AS max_partnership_runs
  FROM partnership_runs
  GROUP BY match_id
),
highest_partnerships AS (
  SELECT pr.*
  FROM partnership_runs pr
  JOIN max_partnership_per_match mp
    ON pr.match_id = mp.match_id AND pr.partnership_runs = mp.max_partnership_runs
)
SELECT
  match_id,
  CASE
    WHEN batter1_runs > batter2_runs THEN batter1
    WHEN batter2_runs > batter1_runs THEN batter2
    WHEN batter1 > batter2 THEN batter1
    ELSE batter2
  END AS player1_id,
  CASE
    WHEN batter1_runs > batter2_runs THEN batter1_runs
    WHEN batter2_runs > batter1_runs THEN batter2_runs
    WHEN batter1 > batter2 THEN batter1_runs
    ELSE batter2_runs
  END AS player1_runs,
  CASE
    WHEN batter1_runs < batter2_runs THEN batter1
    WHEN batter2_runs < batter1_runs THEN batter2
    WHEN batter1 < batter2 THEN batter1
    ELSE batter2
  END AS player2_id,
  CASE
    WHEN batter1_runs < batter2_runs THEN batter1_runs
    WHEN batter2_runs < batter1_runs THEN batter2_runs
    WHEN batter1 < batter2 THEN batter1_runs
    ELSE batter2_runs
  END AS player2_runs,
  partnership_runs
FROM highest_partnerships
ORDER BY match_id;