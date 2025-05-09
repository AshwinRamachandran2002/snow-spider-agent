WITH "ball_runs" AS (               -- runs conceded by every bowler in every over
    SELECT
        b."match_id",
        b."innings_no",
        b."over_id",
        b."bowler"                                                   AS "bowler_id",
        SUM( COALESCE(bs."runs_scored", 0) )                         AS "batsman_runs",
        SUM( COALESCE(er."extra_runs" , 0) )                         AS "extra_runs",
        SUM( COALESCE(bs."runs_scored", 0) ) +
        SUM( COALESCE(er."extra_runs" , 0) )                         AS "total_runs"
    FROM IPL.IPL."BALL_BY_BALL"      b
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs
           ON bs."match_id"   = b."match_id"
          AND bs."innings_no" = b."innings_no"
          AND bs."over_id"    = b."over_id"
          AND bs."ball_id"    = b."ball_id"
    LEFT JOIN IPL.IPL."EXTRA_RUNS"   er
           ON er."match_id"   = b."match_id"
          AND er."innings_no" = b."innings_no"
          AND er."over_id"    = b."over_id"
          AND er."ball_id"    = b."ball_id"
    GROUP BY
        b."match_id",
        b."innings_no",
        b."over_id",
        b."bowler"
), "max_runs_per_match" AS (         -- maximum runs conceded in any over of each match
    SELECT
        "match_id",
        MAX("total_runs") AS "max_runs"
    FROM "ball_runs"
    GROUP BY "match_id"
), "match_max_overs" AS (            -- the overs that actually are those maximum-run overs
    SELECT
        br."match_id",
        br."innings_no",
        br."over_id",
        br."bowler_id",
        br."total_runs"
    FROM "ball_runs"           br
    JOIN "max_runs_per_match"  mm
      ON mm."match_id" = br."match_id"
     AND mm."max_runs" = br."total_runs"
), "bowler_best_over" AS (          -- for each bowler, keep his single most expensive over
    SELECT
        "bowler_id",
        "match_id",
        "total_runs",
        ROW_NUMBER() OVER (PARTITION BY "bowler_id"
                           ORDER BY "total_runs" DESC, "match_id")  AS "rn"
    FROM "match_max_overs"
)
SELECT
    bbo."bowler_id",
    p."player_name"     AS "bowler_name",
    bbo."match_id",
    bbo."total_runs"    AS "runs_conceded"
FROM "bowler_best_over"  bbo
JOIN IPL.IPL."PLAYER"     p
  ON p."player_id" = bbo."bowler_id"
WHERE bbo."rn" = 1
ORDER BY bbo."total_runs" DESC NULLS LAST
FETCH FIRST 3 ROWS ONLY;