WITH PLAYER_RUNS AS (
    /* runs scored by every batsman in every match */
    SELECT
        bb."match_id",
        bb."striker"                 AS "player_id",
        SUM(bs."runs_scored")        AS "total_runs"
    FROM IPL.IPL.BATSMAN_SCORED  bs
    JOIN IPL.IPL.BALL_BY_BALL    bb
      ON  bs."match_id"   = bb."match_id"
      AND bs."innings_no" = bb."innings_no"
      AND bs."over_id"    = bb."over_id"
      AND bs."ball_id"    = bb."ball_id"
    GROUP BY
        bb."match_id",
        bb."striker"
),
CENTURIES AS (
    /* players who scored at least 100 in a match */
    SELECT
        pr."match_id",
        pr."player_id",
        pr."total_runs",
        pm."team_id"
    FROM PLAYER_RUNS           pr
    JOIN IPL.IPL.PLAYER_MATCH  pm
      ON  pr."match_id"  = pm."match_id"
      AND pr."player_id" = pm."player_id"
    WHERE pr."total_runs" >= 100
)
SELECT DISTINCT
       p."player_name"
FROM CENTURIES     c
JOIN IPL.IPL.MATCH m  ON c."match_id" = m."match_id"
JOIN IPL.IPL.PLAYER p ON c."player_id" = p."player_id"
WHERE m."match_winner" IS NOT NULL
  AND c."team_id" <> m."match_winner";