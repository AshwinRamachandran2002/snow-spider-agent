WITH "RUNS_PER_PLAYER_MATCH" AS (
    SELECT
        b."match_id",
        bb."team_batting"         AS "team_id",
        bb."striker"              AS "player_id",
        SUM(b."runs_scored")      AS "total_runs"
    FROM IPL.IPL."BATSMAN_SCORED" b
    JOIN IPL.IPL."BALL_BY_BALL"  bb
      ON  b."match_id"   = bb."match_id"
      AND b."over_id"    = bb."over_id"
      AND b."ball_id"    = bb."ball_id"
      AND b."innings_no" = bb."innings_no"
    GROUP BY
        b."match_id",
        bb."team_batting",
        bb."striker"
),
"CENTURY_FOR_LOSING_TEAM" AS (
    SELECT
        r."player_id"
    FROM "RUNS_PER_PLAYER_MATCH" r
    JOIN IPL.IPL."MATCH" m
      ON r."match_id" = m."match_id"
    WHERE r."total_runs" >= 100           -- scored no less than 100 runs
      AND r."team_id" <> m."match_winner" -- played for the team that lost
)
SELECT DISTINCT
       p."player_name"
FROM "CENTURY_FOR_LOSING_TEAM" cl
JOIN IPL.IPL."PLAYER" p
  ON cl."player_id" = p."player_id";