WITH
batsman_runs AS (
  SELECT
    m."season_id",
    bbb."striker" AS "player_id",
    SUM(bs."runs_scored") AS total_runs
  FROM
    IPL.IPL."MATCH" m
  JOIN IPL.IPL."BALL_BY_BALL" bbb ON m."match_id" = bbb."match_id"
  JOIN IPL.IPL."BATSMAN_SCORED" bs ON
    bbb."match_id" = bs."match_id" AND
    bbb."over_id" = bs."over_id" AND
    bbb."ball_id" = bs."ball_id" AND
    bbb."innings_no" = bs."innings_no"
  GROUP BY
    m."season_id",
    bbb."striker"
),
batsman_ranked AS (
  SELECT
    br.*,
    ROW_NUMBER() OVER (
      PARTITION BY br."season_id"
      ORDER BY br.total_runs DESC NULLS LAST, br."player_id" ASC
    ) AS rn
  FROM
    batsman_runs br
),
top_batsmen AS (
  SELECT
    "season_id",
    MAX(CASE WHEN rn = 1 THEN "player_id" END) AS "Batsman1_id",
    MAX(CASE WHEN rn = 1 THEN total_runs END) AS "Batsman1_Runs",
    MAX(CASE WHEN rn = 2 THEN "player_id" END) AS "Batsman2_id",
    MAX(CASE WHEN rn = 2 THEN total_runs END) AS "Batsman2_Runs",
    MAX(CASE WHEN rn = 3 THEN "player_id" END) AS "Batsman3_id",
    MAX(CASE WHEN rn = 3 THEN total_runs END) AS "Batsman3_Runs"
  FROM
    batsman_ranked
  WHERE
    rn <= 3
  GROUP BY
    "season_id"
),
bowler_wickets AS (
  SELECT
    m."season_id",
    bbb."bowler" AS "player_id",
    COUNT(*) AS total_wickets
  FROM
    IPL.IPL."MATCH" m
  JOIN IPL.IPL."BALL_BY_BALL" bbb ON m."match_id" = bbb."match_id"
  JOIN IPL.IPL."WICKET_TAKEN" wt ON
    bbb."match_id" = wt."match_id" AND
    bbb."over_id" = wt."over_id" AND
    bbb."ball_id" = wt."ball_id" AND
    bbb."innings_no" = wt."innings_no"
  WHERE
    wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
  GROUP BY
    m."season_id",
    bbb."bowler"
),
bowler_ranked AS (
  SELECT
    bw.*,
    ROW_NUMBER() OVER (
      PARTITION BY bw."season_id"
      ORDER BY bw.total_wickets DESC NULLS LAST, bw."player_id" ASC
    ) AS rn
  FROM
    bowler_wickets bw
),
top_bowlers AS (
  SELECT
    "season_id",
    MAX(CASE WHEN rn = 1 THEN "player_id" END) AS "Bowler1_id",
    MAX(CASE WHEN rn = 1 THEN total_wickets END) AS "Bowler1_Wickets",
    MAX(CASE WHEN rn = 2 THEN "player_id" END) AS "Bowler2_id",
    MAX(CASE WHEN rn = 2 THEN total_wickets END) AS "Bowler2_Wickets",
    MAX(CASE WHEN rn = 3 THEN "player_id" END) AS "Bowler3_id",
    MAX(CASE WHEN rn = 3 THEN total_wickets END) AS "Bowler3_Wickets"
  FROM
    bowler_ranked
  WHERE
    rn <= 3
  GROUP BY
    "season_id"
)
SELECT
  tb."season_id" AS "Season",
  pb1."player_name" AS "Batsman1_Name",
  tb."Batsman1_Runs",
  pb2."player_name" AS "Batsman2_Name",
  tb."Batsman2_Runs",
  pb3."player_name" AS "Batsman3_Name",
  tb."Batsman3_Runs",
  pw1."player_name" AS "Bowler1_Name",
  tbo."Bowler1_Wickets",
  pw2."player_name" AS "Bowler2_Name",
  tbo."Bowler2_Wickets",
  pw3."player_name" AS "Bowler3_Name",
  tbo."Bowler3_Wickets"
FROM
  top_batsmen tb
LEFT JOIN IPL.IPL."PLAYER" pb1 ON tb."Batsman1_id" = pb1."player_id"
LEFT JOIN IPL.IPL."PLAYER" pb2 ON tb."Batsman2_id" = pb2."player_id"
LEFT JOIN IPL.IPL."PLAYER" pb3 ON tb."Batsman3_id" = pb3."player_id"
JOIN top_bowlers tbo ON tb."season_id" = tbo."season_id"
LEFT JOIN IPL.IPL."PLAYER" pw1 ON tbo."Bowler1_id" = pw1."player_id"
LEFT JOIN IPL.IPL."PLAYER" pw2 ON tbo."Bowler2_id" = pw2."player_id"
LEFT JOIN IPL.IPL."PLAYER" pw3 ON tbo."Bowler3_id" = pw3."player_id"
ORDER BY
  tb."season_id";