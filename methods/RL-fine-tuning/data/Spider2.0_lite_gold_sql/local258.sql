WITH runs_and_balls AS (
  SELECT
    bb."bowler",
    COUNT(*) AS "total_balls_bowled",
    SUM(bs."runs_scored") AS "total_runs_conceded"
  FROM
    "ball_by_ball" bb
  JOIN
    "batsman_scored" bs ON bb."match_id" = bs."match_id" AND
                           bb."innings_no" = bs."innings_no" AND
                           bb."over_id" = bs."over_id" AND
                           bb."ball_id" = bs."ball_id"
  GROUP BY
    bb."bowler"
),
wickets AS (
  SELECT
    bb."bowler",
    COUNT(*) AS "total_wickets"
  FROM
    "ball_by_ball" bb
  JOIN
    "wicket_taken" wt ON bb."match_id" = wt."match_id" AND
                         bb."innings_no" = wt."innings_no" AND
                         bb."over_id" = wt."over_id" AND
                         bb."ball_id" = wt."ball_id"
  WHERE
    wt."kind_out" != 'run out'
  GROUP BY
    bb."bowler"
),
performance AS (
  SELECT
    bb."bowler",
    bb."match_id",
    SUM(CASE WHEN wt."kind_out" IS NOT NULL AND wt."kind_out" != 'run out' THEN 1 ELSE 0 END) AS "wickets_in_match",
    SUM(bs."runs_scored") AS "runs_conceded_in_match"
  FROM
    "ball_by_ball" bb
  LEFT JOIN
    "wicket_taken" wt ON bb."match_id" = wt."match_id" AND
                         bb."innings_no" = wt."innings_no" AND
                         bb."over_id" = wt."over_id" AND
                         bb."ball_id" = wt."ball_id"
  JOIN
    "batsman_scored" bs ON bb."match_id" = bs."match_id" AND
                           bb."innings_no" = bs."innings_no" AND
                           bb."over_id" = bs."over_id" AND
                           bb."ball_id" = bs."ball_id"
  GROUP BY
    bb."bowler", bb."match_id"
),
max_wickets AS (
  SELECT
    "bowler",
    MAX("wickets_in_match") AS "max_wickets"
  FROM
    performance
  GROUP BY
    "bowler"
),
best_performance AS (
  SELECT
    p."bowler",
    p."wickets_in_match",
    p."runs_conceded_in_match"
  FROM
    performance p
  JOIN
    max_wickets mw ON p."bowler" = mw."bowler" AND p."wickets_in_match" = mw."max_wickets"
),
best_performance_final AS (
  SELECT
    bp."bowler",
    bp."wickets_in_match",
    bp."runs_conceded_in_match"
  FROM
    best_performance bp
  JOIN
    (SELECT "bowler", MIN("runs_conceded_in_match") AS "min_runs"
     FROM best_performance
     GROUP BY "bowler") AS min_runs_per_bowler
    ON bp."bowler" = min_runs_per_bowler."bowler" AND bp."runs_conceded_in_match" = min_runs_per_bowler."min_runs"
)
SELECT
  p."player_name" AS "bowler_name",
  w."total_wickets",
  ROUND((rab."total_runs_conceded" * 1.0) / (rab."total_balls_bowled" / 6.0), 4) AS "economy_rate",
  ROUND((rab."total_balls_bowled" * 1.0) / w."total_wickets", 4) AS "strike_rate",
  printf('%d-%d', bpf."wickets_in_match", bpf."runs_conceded_in_match") AS "best_performance"
FROM
  runs_and_balls rab
JOIN
  wickets w ON rab."bowler" = w."bowler"
JOIN
  best_performance_final bpf ON rab."bowler" = bpf."bowler"
JOIN
  "player" p ON rab."bowler" = p."player_id"
ORDER BY
  p."player_name";