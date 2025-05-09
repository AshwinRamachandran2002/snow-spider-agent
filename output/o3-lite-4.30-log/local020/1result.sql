WITH ball_runs AS (
    SELECT 
        bb."bowler",
        SUM(COALESCE(bs."runs_scored",0)) AS bat_runs
    FROM "ball_by_ball" AS bb
    LEFT JOIN "batsman_scored" AS bs
         ON bs."match_id"   = bb."match_id"
        AND bs."over_id"    = bb."over_id"
        AND bs."ball_id"    = bb."ball_id"
        AND bs."innings_no" = bb."innings_no"
    GROUP BY bb."bowler"
),
extra_runs_on_bowler AS (
    SELECT 
        bb."bowler",
        SUM(er."extra_runs") AS extra_runs
    FROM "ball_by_ball" AS bb
    JOIN "extra_runs" AS er
         ON er."match_id"   = bb."match_id"
        AND er."over_id"    = bb."over_id"
        AND er."ball_id"    = bb."ball_id"
        AND er."innings_no" = bb."innings_no"
    WHERE er."extra_type" IN ('wides','noballs')
    GROUP BY bb."bowler"
),
runs_conceded AS (
    SELECT 
        br."bowler",
        br.bat_runs + COALESCE(er.extra_runs,0) AS total_runs
    FROM ball_runs br
    LEFT JOIN extra_runs_on_bowler er
           ON er."bowler" = br."bowler"
),
wickets_taken AS (
    SELECT 
        bb."bowler",
        COUNT(*) AS wkts
    FROM "wicket_taken" AS wt
    JOIN "ball_by_ball" AS bb
         ON bb."match_id"   = wt."match_id"
        AND bb."over_id"    = wt."over_id"
        AND bb."ball_id"    = wt."ball_id"
        AND bb."innings_no" = wt."innings_no"
    WHERE wt."kind_out" <> 'run out'
    GROUP BY bb."bowler"
),
bowling_avg AS (
    SELECT 
        p."player_name" AS bowler,
        rc.total_runs,
        wt.wkts,
        CAST(rc.total_runs AS REAL) / wt.wkts AS bowling_average
    FROM runs_conceded rc
    JOIN wickets_taken wt ON wt."bowler" = rc."bowler"
    JOIN "player" p       ON p."player_id" = rc."bowler"
    WHERE wt.wkts > 0
)
SELECT 
    bowler,
    printf('%.4f', bowling_average) AS bowling_average
FROM bowling_avg
ORDER BY bowling_average ASC, bowler
LIMIT 1;