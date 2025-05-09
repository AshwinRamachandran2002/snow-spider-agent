WITH total_runs AS (
  SELECT bb."striker" AS "player_id", m."season_id", SUM(bs."runs_scored") AS "total_runs"
  FROM "ball_by_ball" bb
  JOIN "batsman_scored" bs ON bb."match_id" = bs."match_id" 
    AND bb."over_id" = bs."over_id" 
    AND bb."ball_id" = bs."ball_id" 
    AND bb."innings_no" = bs."innings_no"
  JOIN "match" m ON bb."match_id" = m."match_id"
  GROUP BY bb."striker", m."season_id"
),
batsman_ranks AS (
  SELECT
    "player_id",
    "season_id",
    "total_runs",
    ROW_NUMBER() OVER (PARTITION BY "season_id" ORDER BY "total_runs" DESC, "player_id" ASC) AS "rank"
  FROM total_runs
),
top_batsmen AS (
  SELECT * FROM batsman_ranks WHERE "rank" <= 3
),
total_wickets AS (
  SELECT bb."bowler" AS "player_id", m."season_id", COUNT(*) AS "total_wickets"
  FROM "ball_by_ball" bb
  JOIN "wicket_taken" wt ON bb."match_id" = wt."match_id" 
    AND bb."over_id" = wt."over_id" 
    AND bb."ball_id" = wt."ball_id" 
    AND bb."innings_no" = wt."innings_no"
  JOIN "match" m ON bb."match_id" = m."match_id"
  WHERE wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
  GROUP BY bb."bowler", m."season_id"
),
bowler_ranks AS (
  SELECT
    "player_id",
    "season_id",
    "total_wickets",
    ROW_NUMBER() OVER (PARTITION BY "season_id" ORDER BY "total_wickets" DESC, "player_id" ASC) AS "rank"
  FROM total_wickets
),
top_bowlers AS (
  SELECT * FROM bowler_ranks WHERE "rank" <= 3
)

SELECT
  tb."season_id",
  b1."player_id" AS "Batsman1_ID",
  b1."total_runs" AS "Batsman1_TotalRuns",
  bo1."player_id" AS "Bowler1_ID",
  bo1."total_wickets" AS "Bowler1_TotalWickets",
  b2."player_id" AS "Batsman2_ID",
  b2."total_runs" AS "Batsman2_TotalRuns",
  bo2."player_id" AS "Bowler2_ID",
  bo2."total_wickets" AS "Bowler2_TotalWickets",
  b3."player_id" AS "Batsman3_ID",
  b3."total_runs" AS "Batsman3_TotalRuns",
  bo3."player_id" AS "Bowler3_ID",
  bo3."total_wickets" AS "Bowler3_TotalWickets"
FROM
  (SELECT DISTINCT "season_id" FROM "match") tb
LEFT JOIN top_batsmen b1 ON b1."season_id" = tb."season_id" AND b1."rank" = 1
LEFT JOIN top_bowlers bo1 ON bo1."season_id" = tb."season_id" AND bo1."rank" = 1
LEFT JOIN top_batsmen b2 ON b2."season_id" = tb."season_id" AND b2."rank" = 2
LEFT JOIN top_bowlers bo2 ON bo2."season_id" = tb."season_id" AND bo2."rank" = 2
LEFT JOIN top_batsmen b3 ON b3."season_id" = tb."season_id" AND b3."rank" = 3
LEFT JOIN top_bowlers bo3 ON bo3."season_id" = tb."season_id" AND bo3."rank" = 3
ORDER BY tb."season_id" ASC;