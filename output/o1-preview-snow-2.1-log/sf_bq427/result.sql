WITH CorrectShots AS (
  SELECT
    pbp.*
  FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR pbp
  WHERE
    pbp."event_type" IN ('twopointmade', 'twopointmiss', 'threepointmade', 'threepointmiss')
    AND TO_TIMESTAMP_LTZ(pbp."scheduled_date" / 1e6) < DATE '2018-03-15'
    AND (
      (pbp."team_basket" = 'left' AND pbp."event_coord_x" < 564) OR
      (pbp."team_basket" = 'right' AND pbp."event_coord_x" >= 564)
    )
),
GameElapsedTimes AS (
  SELECT DISTINCT "game_id", "elapsed_time_sec"
  FROM CorrectShots
),
TeamsPerGame AS (
  SELECT DISTINCT "game_id", "team_id"
  FROM CorrectShots
),
TimeTeamGrid AS (
  SELECT
    get."game_id",
    get."elapsed_time_sec",
    tpg."team_id"
  FROM GameElapsedTimes get
  JOIN TeamsPerGame tpg
    ON get."game_id" = tpg."game_id"
),
TeamEvents AS (
  SELECT
    "game_id",
    "team_id",
    "elapsed_time_sec",
    COALESCE("points_scored", 0) AS "points_scored"
  FROM CorrectShots
),
TimeTeamPoints AS (
  SELECT
    ttg."game_id",
    ttg."team_id",
    ttg."elapsed_time_sec",
    COALESCE(SUM(te."points_scored"), 0) AS "points_scored"
  FROM TimeTeamGrid ttg
  LEFT JOIN TeamEvents te
    ON ttg."game_id" = te."game_id"
    AND ttg."team_id" = te."team_id"
    AND ttg."elapsed_time_sec" = te."elapsed_time_sec"
  GROUP BY ttg."game_id", ttg."team_id", ttg."elapsed_time_sec"
),
CumulativeTeamScores AS (
  SELECT
    ttp."game_id",
    ttp."team_id",
    ttp."elapsed_time_sec",
    SUM(ttp."points_scored") OVER (
      PARTITION BY ttp."game_id", ttp."team_id"
      ORDER BY CAST(ttp."elapsed_time_sec" AS INT)
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "team_cumulative_points"
  FROM TimeTeamPoints ttp
),
CumulativeScoresWithOpponent AS (
  SELECT
    cts1."game_id",
    cts1."team_id",
    cts1."elapsed_time_sec",
    cts1."team_cumulative_points",
    cts2."team_cumulative_points" AS "opponent_cumulative_points",
    cts1."team_cumulative_points" - cts2."team_cumulative_points" AS "score_delta"
  FROM CumulativeTeamScores cts1
  JOIN CumulativeTeamScores cts2
    ON cts1."game_id" = cts2."game_id"
    AND cts1."elapsed_time_sec" = cts2."elapsed_time_sec"
    AND cts1."team_id" <> cts2."team_id"
),
CategorizedScores AS (
  SELECT
    cts.*,
    CASE
      WHEN cts."score_delta" < -20 THEN '<-20'
      WHEN cts."score_delta" BETWEEN -20 AND -11 THEN '-20 — -11'
      WHEN cts."score_delta" BETWEEN -10 AND -1 THEN '-10 — -1'
      WHEN cts."score_delta" = 0 THEN '0'
      WHEN cts."score_delta" BETWEEN 1 AND 10 THEN '1 — 10'
      WHEN cts."score_delta" BETWEEN 11 AND 20 THEN '11 — 20'
      WHEN cts."score_delta" > 20 THEN '>20'
    END AS "score_delta_interval"
  FROM CumulativeScoresWithOpponent cts
),
ShotsWithDelta AS (
  SELECT
    csd."game_id",
    csd."team_id",
    csd."elapsed_time_sec",
    csd."score_delta_interval",
    csd."score_delta",
    cs."shot_type",
    cs."event_coord_x",
    cs."event_coord_y",
    cs."shot_made"
  FROM CategorizedScores csd
  JOIN CorrectShots cs
    ON csd."game_id" = cs."game_id"
    AND csd."team_id" = cs."team_id"
    AND csd."elapsed_time_sec" = cs."elapsed_time_sec"
),
ShotTypeIntervalCounts AS (
  SELECT
    "shot_type",
    "score_delta_interval",
    COUNT(*) AS "attempts",
    SUM(CASE WHEN "shot_made" = TRUE THEN 1 ELSE 0 END) AS "successful_shots"
  FROM ShotsWithDelta
  GROUP BY "shot_type", "score_delta_interval"
),
MostFrequentIntervals AS (
  SELECT
    "shot_type",
    "score_delta_interval",
    "attempts",
    ROW_NUMBER() OVER (PARTITION BY "shot_type" ORDER BY "attempts" DESC NULLS LAST) AS "rn"
  FROM ShotTypeIntervalCounts
),
MostFrequentPerShotType AS (
  SELECT
    "shot_type",
    "score_delta_interval"
  FROM MostFrequentIntervals
  WHERE "rn" = 1
)
SELECT
  s."shot_type",
  s."score_delta_interval",
  ROUND(AVG(s."event_coord_x"), 4) AS "avg_x",
  ROUND(AVG(s."event_coord_y"), 4) AS "avg_y",
  COUNT(*) AS "avg_attempts",
  SUM(CASE WHEN s."shot_made" = TRUE THEN 1 ELSE 0 END) AS "avg_successful_shots"
FROM ShotsWithDelta s
JOIN MostFrequentPerShotType mf
  ON s."shot_type" = mf."shot_type" AND s."score_delta_interval" = mf."score_delta_interval"
GROUP BY s."shot_type", s."score_delta_interval"
ORDER BY s."shot_type" NULLS LAST
;