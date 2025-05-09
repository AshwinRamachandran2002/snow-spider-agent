WITH
/* 1. keep every delivery only once */
unique_balls AS (
    SELECT DISTINCT
           bb."match_id",
           bb."over_id",
           bb."ball_id",
           bb."innings_no",
           bb."bowler"
    FROM   "ball_by_ball" AS bb
    WHERE  bb."bowler" IS NOT NULL
),

/* 2. flag legal deliveries (wides / no-balls are NOT legal) */
legal_balls AS (
    SELECT  ub.*,
            CASE
              WHEN EXISTS ( SELECT 1
                            FROM   "extra_runs" er
                            WHERE  er."match_id"   = ub."match_id"
                              AND  er."over_id"    = ub."over_id"
                              AND  er."ball_id"    = ub."ball_id"
                              AND  er."innings_no" = ub."innings_no"
                              AND  er."extra_type" IN ('wides','noballs') )
              THEN 0 ELSE 1
            END AS legal
    FROM   unique_balls ub
),

/* 3. runs off the bat conceded on each delivery                      */
runs_per_ball AS (
    SELECT  ub."match_id",
            ub."over_id",
            ub."ball_id",
            ub."innings_no",
            ub."bowler",
            COALESCE(bs."runs_scored",0) AS bat_runs
    FROM   unique_balls          ub
    LEFT JOIN "batsman_scored"   bs
           ON bs."match_id"   = ub."match_id"
          AND bs."over_id"    = ub."over_id"
          AND bs."ball_id"    = ub."ball_id"
          AND bs."innings_no" = ub."innings_no"
),

/* 4. aggregate balls & runs for every bowler                         */
bowler_runs_balls AS (
    SELECT  lb."bowler",
            SUM(lb.legal)          AS legal_balls,
            SUM(rpb.bat_runs)      AS runs_conceded
    FROM   legal_balls    lb
    JOIN   runs_per_ball  rpb
           ON  rpb."match_id"   = lb."match_id"
           AND rpb."over_id"    = lb."over_id"
           AND rpb."ball_id"    = lb."ball_id"
           AND rpb."innings_no" = lb."innings_no"
    GROUP BY lb."bowler"
),

/* 5. wickets credited to each bowler (exclude run-outs etc.)         */
bowler_wkts AS (
    SELECT  bb."bowler",
            COUNT(*) AS total_wkts
    FROM   "wicket_taken" wt
    JOIN   "ball_by_ball" bb
           ON bb."match_id"   = wt."match_id"
          AND bb."over_id"    = wt."over_id"
          AND bb."ball_id"    = wt."ball_id"
          AND bb."innings_no" = wt."innings_no"
    WHERE  wt."kind_out" NOT IN ('run out','retired hurt','obstructing the field')
    GROUP BY bb."bowler"
),

/* 6. combined summary                                                */
bowler_summary AS (
    SELECT  brb."bowler",
            COALESCE(bw.total_wkts,0) AS total_wkts,
            brb.runs_conceded,
            brb.legal_balls
    FROM   bowler_runs_balls brb
    LEFT  JOIN bowler_wkts   bw
           ON bw."bowler" = brb."bowler"
),

/* 7. wickets & runs per bowler per match  (needed for best figures)  */
match_figures AS (
    SELECT  bb."bowler",
            wt."match_id",
            COUNT(*)                  AS wkts,
            SUM(bs."runs_scored")     AS runs_conceded
    FROM    "wicket_taken" wt
    JOIN    "ball_by_ball" bb
            ON bb."match_id"   = wt."match_id"
           AND bb."over_id"    = wt."over_id"
           AND bb."ball_id"    = wt."ball_id"
           AND bb."innings_no" = wt."innings_no"
    JOIN    "batsman_scored"  bs
            ON bs."match_id"   = bb."match_id"
           AND bs."over_id"    = bb."over_id"
           AND bs."ball_id"    = bb."ball_id"
           AND bs."innings_no" = bb."innings_no"
    WHERE   wt."kind_out" NOT IN ('run out','retired hurt','obstructing the field')
    GROUP BY bb."bowler", wt."match_id"
),

/* 8. choose best bowling (most wkts, then fewest runs)               */
best_perf AS (
    SELECT mf."bowler",
           mf.wkts || '-' || mf.runs_conceded AS best_figures
    FROM   match_figures mf
    LEFT  JOIN match_figures mf2
           ON  mf2."bowler" = mf."bowler"
           AND (mf2.wkts  > mf.wkts
                 OR (mf2.wkts = mf.wkts AND mf2.runs_conceded < mf.runs_conceded))
    WHERE  mf2."bowler" IS NULL
)

/* 9. final output                                                    */
SELECT
       p."player_id"                    AS bowler_id,
       p."player_name"                  AS bowler_name,
       bs.total_wkts,
       ROUND(bs.runs_conceded / (bs.legal_balls/6.0),4)          AS economy_rate,
       ROUND(CASE WHEN bs.total_wkts>0
                  THEN bs.legal_balls*1.0/bs.total_wkts END,4)   AS strike_rate,
       bp.best_figures
FROM   bowler_summary  bs
JOIN   "player"        p   ON p."player_id" = bs."bowler"
LEFT  JOIN best_perf   bp  ON bp."bowler"   = bs."bowler"
ORDER BY bs.total_wkts DESC, p."player_name";