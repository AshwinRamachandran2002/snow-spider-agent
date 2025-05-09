WITH "DELIVERIES" AS (          -- every ball bowled with runs conceded
    SELECT
        bb."bowler",
        COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0)  AS "runs_conceded"
    FROM IPL.IPL.BALL_BY_BALL bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"  = bs."match_id"
           AND bb."innings_no"= bs."innings_no"
           AND bb."over_id"   = bs."over_id"
           AND bb."ball_id"   = bs."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS   er
           ON  bb."match_id"  = er."match_id"
           AND bb."innings_no"= er."innings_no"
           AND bb."over_id"   = er."over_id"
           AND bb."ball_id"   = er."ball_id"
), 
"BOWLER_RUNS" AS (              -- total runs conceded by each bowler
    SELECT
        "bowler",
        SUM("runs_conceded") AS "total_runs_conceded"
    FROM "DELIVERIES"
    GROUP BY "bowler"
),
"WICKETS" AS (                  -- wickets credited to each bowler
    SELECT
        bb."bowler",
        COUNT(*) AS "wickets_taken"
    FROM IPL.IPL.WICKET_TAKEN wt
    JOIN IPL.IPL.BALL_BY_BALL bb
         ON  wt."match_id"   = bb."match_id"
         AND wt."innings_no" = bb."innings_no"
         AND wt."over_id"    = bb."over_id"
         AND wt."ball_id"    = bb."ball_id"
    GROUP BY bb."bowler"
),
"STATS" AS (                    -- compute bowling average
    SELECT
        br."bowler",
        br."total_runs_conceded",
        w."wickets_taken",
        br."total_runs_conceded" / w."wickets_taken" AS "bowling_average"
    FROM "BOWLER_RUNS" br
    JOIN "WICKETS"     w  ON br."bowler" = w."bowler"
    WHERE w."wickets_taken" > 0
)
SELECT
    p."player_name"                                  AS "bowler_name",
    ROUND(s."bowling_average",4)                     AS "bowling_average"
FROM "STATS" s
JOIN IPL.IPL.PLAYER p  ON s."bowler" = p."player_id"
ORDER BY s."bowling_average" ASC NULLS LAST          -- lowest average first
LIMIT 1;