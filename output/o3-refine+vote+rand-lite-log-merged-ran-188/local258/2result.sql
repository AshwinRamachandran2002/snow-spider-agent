WITH
-- 1)  Balls delivered by every bowler together with the runs scored off the bat
legal_balls AS (
    SELECT  bb."bowler",
            COUNT(*)                                            AS balls_bowled,
            SUM( COALESCE(bs."runs_scored",0) )                AS runs_conceded
    FROM    "ball_by_ball"      AS bb
    LEFT JOIN "batsman_scored"  AS bs
           ON  bb."match_id"    = bs."match_id"
          AND bb."over_id"      = bs."over_id"
          AND bb."ball_id"      = bs."ball_id"
          AND bb."innings_no"   = bs."innings_no"
    GROUP BY bb."bowler"
),

-- 2)  Wickets that are credited to the bowler (run-outs, retired-hurt … ignored)
bowler_wkts AS (
    SELECT  bb."bowler",
            COUNT(*)                           AS total_wickets
    FROM    "wicket_taken"  AS wt
    JOIN    "ball_by_ball" AS bb
           ON  wt."match_id"  = bb."match_id"
          AND wt."over_id"    = bb."over_id"
          AND wt."ball_id"    = bb."ball_id"
          AND wt."innings_no" = bb."innings_no"
    WHERE   wt."kind_out" NOT LIKE 'run out%'
      AND   wt."kind_out" NOT LIKE 'retired%'
      AND   wt."kind_out" NOT LIKE 'obstruct%'
    GROUP BY bb."bowler"
),

-- 3)  Per-match figures for each bowler (needed for “best bowling”)
match_figs AS (
    SELECT  bb."bowler",
            bb."match_id",
            SUM( CASE
                    WHEN wt."kind_out" NOT LIKE 'run out%'
                     AND wt."kind_out" NOT LIKE 'retired%'
                     AND wt."kind_out" NOT LIKE 'obstruct%' THEN 1
                    ELSE 0
                 END )                               AS wkts_in_match,
            SUM( COALESCE(bs."runs_scored",0) )      AS runs_in_match
    FROM    "ball_by_ball"     AS bb
    LEFT JOIN "wicket_taken"   AS wt
           ON  wt."match_id"   = bb."match_id"
          AND wt."over_id"     = bb."over_id"
          AND wt."ball_id"     = bb."ball_id"
          AND wt."innings_no"  = bb."innings_no"
    LEFT JOIN "batsman_scored" AS bs
           ON  bb."match_id"   = bs."match_id"
          AND bb."over_id"     = bs."over_id"
          AND bb."ball_id"     = bs."ball_id"
          AND bb."innings_no"  = bs."innings_no"
    GROUP BY bb."bowler", bb."match_id"
),

-- 4)  For every bowler, locate the match with the highest wicket haul
best_per_bowler AS (
    /* first, the max wickets */
    SELECT  mf."bowler",
            MAX(mf.wkts_in_match)                  AS max_wkts
    FROM    match_figs mf
    GROUP BY mf."bowler"
),
-- …then, within those matches, choose the one with least runs conceded
best_match AS (
    SELECT  mf."bowler",
            mf.wkts_in_match   AS best_wkts,
            MIN(mf.runs_in_match)  AS best_runs
    FROM    match_figs mf
    JOIN    best_per_bowler bw
          ON mf."bowler"      = bw."bowler"
         AND mf.wkts_in_match = bw.max_wkts
    GROUP BY mf."bowler"
)

SELECT  p."player_id"                       AS bowler_id,
        p."player_name",
        COALESCE(w.total_wickets,0)         AS total_wickets,
        ROUND( lb.runs_conceded*6.0 / lb.balls_bowled , 4)  AS economy_rate,
        CASE 
            WHEN w.total_wickets > 0 
            THEN ROUND( 1.0*lb.balls_bowled / w.total_wickets , 4)
            ELSE NULL
        END                                 AS strike_rate,
        ( best.best_wkts || '-' || best.best_runs )         AS best_bowling
FROM        legal_balls      lb
LEFT JOIN   bowler_wkts      w    ON lb."bowler" = w."bowler"
LEFT JOIN   best_match       best ON lb."bowler" = best."bowler"
LEFT JOIN   player           p    ON lb."bowler" = p."player_id"
ORDER BY    total_wickets DESC,
            p."player_name";