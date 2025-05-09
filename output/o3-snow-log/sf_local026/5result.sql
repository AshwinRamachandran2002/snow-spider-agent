WITH BALL_RUNS AS (      -- runs conceded on every ball
    SELECT
        b."match_id",
        b."innings_no",
        b."over_id",
        b."bowler",
        COALESCE(bs."runs_scored", 0) AS batsman_runs,
        COALESCE(er."extra_runs", 0)  AS extra_runs
    FROM "IPL"."IPL"."BALL_BY_BALL" b
    LEFT JOIN "IPL"."IPL"."BATSMAN_SCORED" bs
           ON bs."match_id"   = b."match_id"
          AND bs."innings_no" = b."innings_no"
          AND bs."over_id"    = b."over_id"
          AND bs."ball_id"    = b."ball_id"
    LEFT JOIN "IPL"."IPL"."EXTRA_RUNS" er
           ON er."match_id"   = b."match_id"
          AND er."innings_no" = b."innings_no"
          AND er."over_id"    = b."over_id"
          AND er."ball_id"    = b."ball_id"
),
OVER_RUNS AS (           -- runs conceded in every over by a bowler
    SELECT
        "match_id",
        "over_id",
        "bowler",
        SUM(batsman_runs + extra_runs) AS runs_conceded
    FROM BALL_RUNS
    GROUP BY "match_id", "over_id", "bowler"
),
MAX_MATCH_OVER AS (      -- maximum-run over of each match
    SELECT
        "match_id",
        MAX(runs_conceded) AS max_runs_in_match
    FROM OVER_RUNS
    GROUP BY "match_id"
),
MAX_OVERS_DETAIL AS (    -- only those overs that equal the match maximum
    SELECT o.*
    FROM OVER_RUNS o
    JOIN MAX_MATCH_OVER m
      ON m."match_id" = o."match_id"
     AND m.max_runs_in_match = o.runs_conceded
),
BOWLER_WORST_OVER AS (   -- per bowler, keep his single worst such over
    SELECT
        "bowler",
        "match_id",
        runs_conceded,
        ROW_NUMBER() OVER (PARTITION BY "bowler"
                           ORDER BY runs_conceded DESC, "match_id") AS rn
    FROM MAX_OVERS_DETAIL
)
SELECT
    p."player_name" AS "bowler_name",
    b."bowler"      AS "bowler_id",
    b."match_id",
    b.runs_conceded
FROM BOWLER_WORST_OVER b
JOIN "IPL"."IPL"."PLAYER" p
  ON p."player_id" = b."bowler"
WHERE b.rn = 1
ORDER BY b.runs_conceded DESC NULLS LAST
LIMIT 3;