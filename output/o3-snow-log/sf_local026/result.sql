WITH ball_runs AS (          -- runs scored on every delivery
    SELECT
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        bb."bowler"                          AS "bowler_id",
        COALESCE(bs."runs_scored",0)
      + COALESCE(er."extra_runs",0)          AS "runs"
    FROM IPL.IPL.BALL_BY_BALL   bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."innings_no" = bs."innings_no"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS    er
           ON  bb."match_id"   = er."match_id"
           AND bb."innings_no" = er."innings_no"
           AND bb."over_id"    = er."over_id"
           AND bb."ball_id"    = er."ball_id"
), over_runs AS (            -- total runs conceded in every over by its bowler
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        "bowler_id",
        SUM("runs")           AS "over_runs"
    FROM ball_runs
    GROUP BY
        "match_id",
        "innings_no",
        "over_id",
        "bowler_id"
), match_max_overs AS (      -- overs that are the costliest in their match
    SELECT
        o.*,
        MAX("over_runs") OVER (PARTITION BY "match_id") AS "match_max_runs"
    FROM over_runs o
), only_max_overs AS (
    SELECT *
    FROM   match_max_overs
    WHERE  "over_runs" = "match_max_runs"
), ranked_overs AS (         -- rank the costliest overs across all matches
    SELECT
        om."bowler_id",
        p."player_name"       AS "bowler_name",
        om."match_id",
        om."over_runs",
        ROW_NUMBER() OVER (
            ORDER BY om."over_runs" DESC, om."bowler_id"
        )                    AS rn
    FROM   only_max_overs om
    JOIN   IPL.IPL.PLAYER p
           ON om."bowler_id" = p."player_id"
)
SELECT
    "bowler_name",
    "match_id",
    "over_runs"
FROM   ranked_overs
WHERE  rn <= 3
ORDER BY "over_runs" DESC NULLS LAST;