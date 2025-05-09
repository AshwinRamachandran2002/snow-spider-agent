WITH MostFrequentRole AS (
  SELECT
    pm."player_id",
    pm."role",
    COUNT(*) AS "role_count",
    ROW_NUMBER() OVER (PARTITION BY pm."player_id" ORDER BY COUNT(*) DESC) AS rn
  FROM IPL.IPL.PLAYER_MATCH pm
  GROUP BY pm."player_id", pm."role"
),
RunsScored AS (
  SELECT
    bb."striker" AS "player_id",
    SUM(bs."runs_scored") AS "total_runs_scored"
  FROM IPL.IPL.BALL_BY_BALL bb
  JOIN IPL.IPL.BATSMAN_SCORED bs
    ON bb."match_id" = bs."match_id"
    AND bb."over_id" = bs."over_id"
    AND bb."ball_id" = bs."ball_id"
    AND bb."innings_no" = bs."innings_no"
  GROUP BY bb."striker"
),
MatchesPlayed AS (
  SELECT
    pm."player_id",
    COUNT(DISTINCT pm."match_id") AS "total_matches_played"
  FROM IPL.IPL.PLAYER_MATCH pm
  GROUP BY pm."player_id"
),
TotalDismissals AS (
  SELECT
    wt."player_out" AS "player_id",
    COUNT(*) AS "total_dismissals"
  FROM IPL.IPL.WICKET_TAKEN wt
  GROUP BY wt."player_out"
),
PlayerMatchScores AS (
  SELECT
    bb."striker" AS "player_id",
    bb."match_id",
    SUM(bs."runs_scored") AS "match_runs"
  FROM IPL.IPL.BALL_BY_BALL bb
  JOIN IPL.IPL.BATSMAN_SCORED bs
    ON bb."match_id" = bs."match_id"
    AND bb."over_id" = bs."over_id"
    AND bb."ball_id" = bs."ball_id"
    AND bb."innings_no" = bs."innings_no"
  GROUP BY bb."striker", bb."match_id"
),
HighestScore AS (
  SELECT
    pms."player_id",
    MAX(pms."match_runs") AS "highest_score_in_match"
  FROM PlayerMatchScores pms
  GROUP BY pms."player_id"
),
MatchesOver30 AS (
  SELECT
    pms."player_id",
    COUNT(*) AS "matches_scored_over_30"
  FROM PlayerMatchScores pms
  WHERE pms."match_runs" > 30
  GROUP BY pms."player_id"
),
MatchesOver50 AS (
  SELECT
    pms."player_id",
    COUNT(*) AS "matches_scored_over_50"
  FROM PlayerMatchScores pms
  WHERE pms."match_runs" > 50
  GROUP BY pms."player_id"
),
MatchesOver100 AS (
  SELECT
    pms."player_id",
    COUNT(*) AS "matches_scored_over_100"
  FROM PlayerMatchScores pms
  WHERE pms."match_runs" > 100
  GROUP BY pms."player_id"
),
BallsFaced AS (
  SELECT
    bb."striker" AS "player_id",
    COUNT(*) AS "total_balls_faced"
  FROM IPL.IPL.BALL_BY_BALL bb
  GROUP BY bb."striker"
),
WicketsTaken AS (
  SELECT
    bb."bowler" AS "player_id",
    COUNT(*) AS "total_wickets_taken"
  FROM IPL.IPL.WICKET_TAKEN wt
  JOIN IPL.IPL.BALL_BY_BALL bb
    ON wt."match_id" = bb."match_id"
    AND wt."over_id" = bb."over_id"
    AND wt."ball_id" = bb."ball_id"
    AND wt."innings_no" = bb."innings_no"
  GROUP BY bb."bowler"
),
BowlingStats AS (
  SELECT
    bb."bowler" AS "player_id",
    COUNT(*) AS "balls_bowled",
    SUM(bs."runs_scored") AS "runs_conceded"
  FROM IPL.IPL.BALL_BY_BALL bb
  JOIN IPL.IPL.BATSMAN_SCORED bs
    ON bb."match_id" = bs."match_id"
    AND bb."over_id" = bs."over_id"
    AND bb."ball_id" = bs."ball_id"
    AND bb."innings_no" = bs."innings_no"
  GROUP BY bb."bowler"
),
BowlingPerformance AS (
  SELECT
    bp."player_id",
    bp."wickets_taken",
    bp."runs_conceded",
    ROW_NUMBER() OVER (
      PARTITION BY bp."player_id"
      ORDER BY bp."wickets_taken" DESC, bp."runs_conceded" ASC
    ) AS rn
  FROM (
    SELECT
      bb."bowler" AS "player_id",
      bb."match_id",
      COUNT(DISTINCT wt."player_out") AS "wickets_taken",
      SUM(bs."runs_scored") AS "runs_conceded"
    FROM IPL.IPL.BALL_BY_BALL bb
    LEFT JOIN IPL.IPL.WICKET_TAKEN wt
      ON bb."match_id" = wt."match_id"
      AND bb."over_id" = wt."over_id"
      AND bb."ball_id" = wt."ball_id"
      AND bb."innings_no" = wt."innings_no"
    JOIN IPL.IPL.BATSMAN_SCORED bs
      ON bb."match_id" = bs."match_id"
      AND bb."over_id" = bs."over_id"
      AND bb."ball_id" = bs."ball_id"
      AND bb."innings_no" = bs."innings_no"
    GROUP BY bb."bowler", bb."match_id"
  ) bp
  WHERE bp."wickets_taken" > 0
)
SELECT
  p."player_id" AS "Player_ID",
  p."player_name" AS "Name",
  mfr."role" AS "Most_Frequent_Role",
  p."batting_hand" AS "Batting_Hand",
  p."bowling_skill" AS "Bowling_Skill",
  rs."total_runs_scored" AS "Total_Runs_Scored",
  mp."total_matches_played" AS "Total_Matches_Played",
  td."total_dismissals" AS "Total_Dismissals",
  ROUND(CAST(rs."total_runs_scored" AS FLOAT) / NULLIF(td."total_dismissals", 0), 4) AS "Batting_Average",
  hs."highest_score_in_match" AS "Highest_Score_In_Single_Match",
  mo30."matches_scored_over_30" AS "Matches_Scored_Over_30",
  mo50."matches_scored_over_50" AS "Matches_Scored_Over_50",
  mo100."matches_scored_over_100" AS "Matches_Scored_Over_100",
  bf."total_balls_faced" AS "Total_Balls_Faced",
  ROUND(rs."total_runs_scored" * 100.0 / NULLIF(bf."total_balls_faced", 0), 4) AS "Strike_Rate",
  wt."total_wickets_taken" AS "Total_Wickets_Taken",
  ROUND(bs."runs_conceded" * 6.0 / NULLIF(bs."balls_bowled", 0), 4) AS "Economy_Rate",
  CONCAT(bperf."wickets_taken", '-', bperf."runs_conceded") AS "Best_Bowling_Performance"
FROM IPL.IPL.PLAYER p
LEFT JOIN (
  SELECT "player_id", "role"
  FROM MostFrequentRole
  WHERE rn = 1
) mfr ON p."player_id" = mfr."player_id"
LEFT JOIN RunsScored rs ON p."player_id" = rs."player_id"
LEFT JOIN MatchesPlayed mp ON p."player_id" = mp."player_id"
LEFT JOIN TotalDismissals td ON p."player_id" = td."player_id"
LEFT JOIN HighestScore hs ON p."player_id" = hs."player_id"
LEFT JOIN MatchesOver30 mo30 ON p."player_id" = mo30."player_id"
LEFT JOIN MatchesOver50 mo50 ON p."player_id" = mo50."player_id"
LEFT JOIN MatchesOver100 mo100 ON p."player_id" = mo100."player_id"
LEFT JOIN BallsFaced bf ON p."player_id" = bf."player_id"
LEFT JOIN WicketsTaken wt ON p."player_id" = wt."player_id"
LEFT JOIN BowlingStats bs ON p."player_id" = bs."player_id"
LEFT JOIN (
  SELECT
    bp."player_id",
    bp."wickets_taken",
    bp."runs_conceded"
  FROM BowlingPerformance bp
  WHERE bp.rn = 1
) bperf ON p."player_id" = bperf."player_id"
ORDER BY p."player_id" NULLS LAST;