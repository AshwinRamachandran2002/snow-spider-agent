WITH over_runs AS (
    SELECT  bb."match_id",
            bb."over_id",
            bb."innings_no",
            bb."bowler",
            SUM(bs."runs_scored") + SUM(COALESCE(er."extra_runs",0)) AS "total_runs"
    FROM    "ball_by_ball" AS bb
    LEFT JOIN "batsman_scored" AS bs
           ON  bb."match_id" = bs."match_id"
           AND bb."over_id"  = bs."over_id"
           AND bb."ball_id"  = bs."ball_id"
           AND bb."innings_no" = bs."innings_no"
    LEFT JOIN "extra_runs"   AS er
           ON  bb."match_id" = er."match_id"
           AND bb."over_id"  = er."over_id"
           AND bb."ball_id"  = er."ball_id"
           AND bb."innings_no" = er."innings_no"
    GROUP BY bb."match_id", bb."over_id", bb."innings_no", bb."bowler"
),
match_max AS (
    SELECT "match_id",
           MAX("total_runs") AS "max_runs_in_match"
    FROM   over_runs
    GROUP  BY "match_id"
),
costliest_overs AS (
    SELECT o."match_id",
           o."bowler",
           o."total_runs"
    FROM   over_runs AS o
    JOIN   match_max  AS m
         ON o."match_id" = m."match_id"
        AND o."total_runs" = m."max_runs_in_match"
),
bowler_best AS (
    SELECT  "bowler",
            MAX("total_runs") AS "best_runs"
    FROM    costliest_overs
    GROUP  BY "bowler"
),
bowler_best_match AS (
    -- if a bowler recorded the same best figure in multiple matches,
    -- pick the earliest match_id
    SELECT  bb."bowler",
            MIN(co."match_id") AS "match_id",
            bb."best_runs"     AS "total_runs"
    FROM    bowler_best   AS bb
    JOIN    costliest_overs AS co
           ON  co."bowler"      = bb."bowler"
           AND co."total_runs"  = bb."best_runs"
    GROUP  BY bb."bowler"
)
SELECT  p."player_name"       AS "bowler_name",
        bm."match_id",
        bm."total_runs"
FROM    bowler_best_match AS bm
JOIN    "player"          AS p
       ON p."player_id" = bm."bowler"
ORDER  BY bm."total_runs" DESC
LIMIT 3;