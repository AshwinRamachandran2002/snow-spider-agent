WITH player_roles AS (
  SELECT
    "player_id",
    "role",
    COUNT(*) AS role_count,
    ROW_NUMBER() OVER (
      PARTITION BY "player_id"
      ORDER BY COUNT(*) DESC
    ) AS rn
  FROM "IPL"."IPL"."PLAYER_MATCH"
  GROUP BY "player_id", "role"
),
player_most_frequent_role AS (
  SELECT "player_id", "role" AS "most_frequent_role"
  FROM player_roles
  WHERE rn = 1
),
total_runs_scored AS (
  SELECT
    "BALL_BY_BALL"."striker" AS "player_id",
    SUM("BATSMAN_SCORED"."runs_scored") AS "total_runs_scored"
  FROM "IPL"."IPL"."BATSMAN_SCORED"
  JOIN "IPL"."IPL"."BALL_BY_BALL"
    ON "BATSMAN_SCORED"."match_id" = "BALL_BY_BALL"."match_id"
    AND "BATSMAN_SCORED"."over_id" = "BALL_BY_BALL"."over_id"
    AND "BATSMAN_SCORED"."ball_id" = "BALL_BY_BALL"."ball_id"
  GROUP BY "BALL_BY_BALL"."striker"
),
total_matches_played AS (
  SELECT
    "player_id",
    COUNT(DISTINCT "match_id") AS "total_matches_played"
  FROM "IPL"."IPL"."PLAYER_MATCH"
  GROUP BY "player_id"
),
total_dismissals AS (
  SELECT
    "player_out" AS "player_id",
    COUNT(*) AS "total_dismissals"
  FROM "IPL"."IPL"."WICKET_TAKEN"
  GROUP BY "player_out"
),
batting_average AS (
  SELECT
    tr."player_id",
    tr."total_runs_scored",
    td."total_dismissals",
    CASE WHEN td."total_dismissals" > 0 THEN
      ROUND(CAST(tr."total_runs_scored" AS FLOAT) / td."total_dismissals", 4)
    ELSE NULL END AS "batting_average"
  FROM total_runs_scored tr
  LEFT JOIN total_dismissals td
    ON tr."player_id" = td."player_id"
),
highest_score_per_match AS (
  SELECT
    "player_id",
    MAX("runs_in_match") AS "highest_score"
  FROM (
    SELECT
      "BALL_BY_BALL"."striker" AS "player_id",
      "BALL_BY_BALL"."match_id",
      SUM("BATSMAN_SCORED"."runs_scored") AS "runs_in_match"
    FROM "IPL"."IPL"."BATSMAN_SCORED"
    JOIN "IPL"."IPL"."BALL_BY_BALL"
      ON "BATSMAN_SCORED"."match_id" = "BALL_BY_BALL"."match_id"
      AND "BATSMAN_SCORED"."over_id" = "BALL_BY_BALL"."over_id"
      AND "BATSMAN_SCORED"."ball_id" = "BALL_BY_BALL"."ball_id"
    GROUP BY "BALL_BY_BALL"."striker", "BALL_BY_BALL"."match_id"
  ) player_match_scores
  GROUP BY "player_id"
),
matches_scored_over AS (
  SELECT
    "player_id",
    SUM(CASE WHEN "runs_in_match" > 30 THEN 1 ELSE 0 END) AS "matches_scored_over_30",
    SUM(CASE WHEN "runs_in_match" > 50 THEN 1 ELSE 0 END) AS "matches_scored_over_50",
    SUM(CASE WHEN "runs_in_match" > 100 THEN 1 ELSE 0 END) AS "matches_scored_over_100"
  FROM (
    SELECT
      "BALL_BY_BALL"."striker" AS "player_id",
      "BALL_BY_BALL"."match_id",
      SUM("BATSMAN_SCORED"."runs_scored") AS "runs_in_match"
    FROM "IPL"."IPL"."BATSMAN_SCORED"
    JOIN "IPL"."IPL"."BALL_BY_BALL"
      ON "BATSMAN_SCORED"."match_id" = "BALL_BY_BALL"."match_id"
      AND "BATSMAN_SCORED"."over_id" = "BALL_BY_BALL"."over_id"
      AND "BATSMAN_SCORED"."ball_id" = "BALL_BY_BALL"."ball_id"
    GROUP BY "BALL_BY_BALL"."striker", "BALL_BY_BALL"."match_id"
  ) player_match_scores
  GROUP BY "player_id"
),
total_balls_faced AS (
  SELECT
    "striker" AS "player_id",
    COUNT(*) AS "total_balls_faced"
  FROM "IPL"."IPL"."BALL_BY_BALL"
  GROUP BY "striker"
),
strike_rate AS (
  SELECT
    tr."player_id",
    tr."total_runs_scored",
    tbf."total_balls_faced",
    CASE WHEN tbf."total_balls_faced" >0 THEN
      ROUND((CAST(tr."total_runs_scored" AS FLOAT) / tbf."total_balls_faced") * 100, 4)
    ELSE NULL END AS "strike_rate"
  FROM total_runs_scored tr
  JOIN total_balls_faced tbf
    ON tr."player_id" = tbf."player_id"
),
total_wickets_taken AS (
  SELECT
    "BALL_BY_BALL"."bowler" AS "player_id",
    COUNT(*) AS "total_wickets_taken"
  FROM "IPL"."IPL"."WICKET_TAKEN"
  JOIN "IPL"."IPL"."BALL_BY_BALL"
    ON "WICKET_TAKEN"."match_id" = "BALL_BY_BALL"."match_id"
    AND "WICKET_TAKEN"."over_id" = "BALL_BY_BALL"."over_id"
    AND "WICKET_TAKEN"."ball_id" = "BALL_BY_BALL"."ball_id"
  GROUP BY "BALL_BY_BALL"."bowler"
),
bowler_runs_and_balls AS (
  SELECT
    "BALL_BY_BALL"."bowler" AS "player_id",
    COUNT(*) AS "total_balls_bowled",
    SUM("BATSMAN_SCORED"."runs_scored") AS "total_runs_given"
  FROM "IPL"."IPL"."BATSMAN_SCORED"
  JOIN "IPL"."IPL"."BALL_BY_BALL"
    ON "BATSMAN_SCORED"."match_id" = "BALL_BY_BALL"."match_id"
    AND "BATSMAN_SCORED"."over_id" = "BALL_BY_BALL"."over_id"
    AND "BATSMAN_SCORED"."ball_id" = "BALL_BY_BALL"."ball_id"
  GROUP BY "BALL_BY_BALL"."bowler"
),
bowler_economy AS (
  SELECT
    brb."player_id",
    brb."total_runs_given",
    brb."total_balls_bowled",
    CASE WHEN brb."total_balls_bowled" > 0 THEN
      ROUND((CAST(brb."total_runs_given" AS FLOAT) / brb."total_balls_bowled") * 6, 4)
    ELSE NULL END AS "economy_rate"
  FROM bowler_runs_and_balls brb
),
best_bowling_performance AS (
  SELECT
    "player_id",
    "wickets_taken_in_match" AS "max_wickets_taken",
    "runs_conceded_in_match"
  FROM (
    SELECT
      "bowler" AS "player_id",
      "match_id",
      "wickets_taken_in_match",
      "runs_conceded_in_match",
      ROW_NUMBER() OVER (
        PARTITION BY "bowler"
        ORDER BY "wickets_taken_in_match" DESC, "runs_conceded_in_match" ASC
      ) AS rn
    FROM (
      SELECT
        "BALL_BY_BALL"."bowler",
        "BALL_BY_BALL"."match_id",
        COUNT(DISTINCT "WICKET_TAKEN"."player_out") AS "wickets_taken_in_match",
        SUM("BATSMAN_SCORED"."runs_scored") AS "runs_conceded_in_match"
      FROM "IPL"."IPL"."BALL_BY_BALL"
      LEFT JOIN "IPL"."IPL"."WICKET_TAKEN"
        ON "BALL_BY_BALL"."match_id" = "WICKET_TAKEN"."match_id"
        AND "BALL_BY_BALL"."over_id" = "WICKET_TAKEN"."over_id"
        AND "BALL_BY_BALL"."ball_id" = "WICKET_TAKEN"."ball_id"
      LEFT JOIN "IPL"."IPL"."BATSMAN_SCORED"
        ON "BALL_BY_BALL"."match_id" = "BATSMAN_SCORED"."match_id"
        AND "BALL_BY_BALL"."over_id" = "BATSMAN_SCORED"."over_id"
        AND "BALL_BY_BALL"."ball_id" = "BATSMAN_SCORED"."ball_id"
      GROUP BY
        "BALL_BY_BALL"."bowler",
        "BALL_BY_BALL"."match_id"
    ) match_performance
  ) WHERE rn = 1
)

SELECT
  p."player_id" AS "Player_ID",
  p."player_name" AS "Name",
  pmfr."most_frequent_role" AS "Most_Frequent_Role",
  p."batting_hand" AS "Batting_Hand",
  p."bowling_skill" AS "Bowling_Skill",
  tr."total_runs_scored" AS "Total_Runs_Scored",
  tmp."total_matches_played" AS "Total_Matches_Played",
  td."total_dismissals" AS "Total_Dismissals",
  ba."batting_average" AS "Batting_Average",
  hs."highest_score" AS "Highest_Score_In_Single_Match",
  mso."matches_scored_over_30" AS "Matches_Scored_Over_30",
  mso."matches_scored_over_50" AS "Matches_Scored_Over_50",
  mso."matches_scored_over_100" AS "Matches_Scored_Over_100",
  tbf."total_balls_faced" AS "Total_Balls_Faced",
  sr."strike_rate" AS "Strike_Rate",
  twt."total_wickets_taken" AS "Total_Wickets_Taken",
  be."economy_rate" AS "Economy_Rate",
  CASE WHEN bb."max_wickets_taken" IS NOT NULL AND bb."runs_conceded_in_match" IS NOT NULL
    THEN CONCAT(bb."max_wickets_taken", '-', bb."runs_conceded_in_match")
    ELSE NULL END AS "Best_Bowling_Performance"
FROM "IPL"."IPL"."PLAYER" p
LEFT JOIN player_most_frequent_role pmfr ON p."player_id" = pmfr."player_id"
LEFT JOIN total_runs_scored tr ON p."player_id" = tr."player_id"
LEFT JOIN total_matches_played tmp ON p."player_id" = tmp."player_id"
LEFT JOIN total_dismissals td ON p."player_id" = td."player_id"
LEFT JOIN batting_average ba ON p."player_id" = ba."player_id"
LEFT JOIN highest_score_per_match hs ON p."player_id" = hs."player_id"
LEFT JOIN matches_scored_over mso ON p."player_id" = mso."player_id"
LEFT JOIN total_balls_faced tbf ON p."player_id" = tbf."player_id"
LEFT JOIN strike_rate sr ON p."player_id" = sr."player_id"
LEFT JOIN total_wickets_taken twt ON p."player_id" = twt."player_id"
LEFT JOIN bowler_economy be ON p."player_id" = be."player_id"
LEFT JOIN best_bowling_performance bb ON p."player_id" = bb."player_id"
ORDER BY p."player_id";