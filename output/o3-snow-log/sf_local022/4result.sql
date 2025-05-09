/*  Players who scored at least 100 runs in a match
    but represented the side that did NOT win that match  */
WITH "PLAYER_RUNS" AS (
    SELECT
        bb."match_id",
        bb."striker"                     AS "player_id",
        SUM(bs."runs_scored")            AS "total_runs"
    FROM IPL.IPL."BATSMAN_SCORED"  bs
    JOIN IPL.IPL."BALL_BY_BALL"    bb
      ON  bs."match_id"   = bb."match_id"
      AND bs."over_id"    = bb."over_id"
      AND bs."ball_id"    = bb."ball_id"
      AND bs."innings_no" = bb."innings_no"
    GROUP BY bb."match_id", bb."striker"
    HAVING SUM(bs."runs_scored") >= 100
),
"PLAYER_TEAM" AS (         -- player’s team in that particular match
    SELECT DISTINCT
        "match_id",
        "player_id",
        "team_id"
    FROM IPL.IPL."PLAYER_MATCH"
),
"LOST_CENTURIES" AS (
    SELECT
        pr."player_id",
        pr."match_id"
    FROM "PLAYER_RUNS"  pr
    JOIN "PLAYER_TEAM"  pt
          ON pr."match_id" = pt."match_id"
         AND pr."player_id" = pt."player_id"
    JOIN IPL.IPL."MATCH" m
          ON pr."match_id" = m."match_id"
    WHERE  m."match_winner" IS NULL                 -- tie / no-result
       OR pt."team_id" <> m."match_winner"          -- player’s side lost
)
SELECT DISTINCT
       p."player_name"
FROM "LOST_CENTURIES" lc
JOIN IPL.IPL."PLAYER" p
  ON lc."player_id" = p."player_id"
ORDER BY p."player_name" NULLS LAST;