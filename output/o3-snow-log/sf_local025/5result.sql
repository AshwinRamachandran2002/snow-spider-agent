/*  Average runs of the single highest-scoring over in every match                */
/*  (runs = batsman runs + extras, bowler taken from BALL_BY_BALL)                */

WITH over_totals AS (                -- 1. runs (batsman + extras) per over
    SELECT
        b."match_id",
        b."innings_no",
        b."over_id",
        SUM(b."runs_scored") + COALESCE(SUM(e."extra_runs"),0) AS "total_over_runs"
    FROM "IPL"."IPL"."BATSMAN_SCORED" b
    LEFT JOIN "IPL"."IPL"."EXTRA_RUNS" e
           ON  b."match_id"   = e."match_id"
           AND b."innings_no" = e."innings_no"
           AND b."over_id"    = e."over_id"
           AND b."ball_id"    = e."ball_id"
    GROUP BY b."match_id", b."innings_no", b."over_id"
),

over_with_bowler AS (               -- 2. attach bowler for every over
    SELECT
        o."match_id",
        o."innings_no",
        o."over_id",
        o."total_over_runs",
        MIN(bb."bowler") AS "bowler_id"          -- one bowler per over
    FROM over_totals o
    JOIN "IPL"."IPL"."BALL_BY_BALL" bb
      ON  o."match_id"   = bb."match_id"
      AND o."innings_no" = bb."innings_no"
      AND o."over_id"    = bb."over_id"
    GROUP BY o."match_id", o."innings_no", o."over_id", o."total_over_runs"
),

match_highest_over AS (             -- 3. keep the single highest-scoring over per match
    SELECT
        owb.*,
        ROW_NUMBER() OVER (PARTITION BY owb."match_id"
                           ORDER BY owb."total_over_runs" DESC NULLS LAST) AS "rn"
    FROM over_with_bowler owb
)

SELECT
    ROUND(AVG(mho."total_over_runs"), 4) AS "average_highest_over_runs"
FROM match_highest_over mho
WHERE mho."rn" = 1;