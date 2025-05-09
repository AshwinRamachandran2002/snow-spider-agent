/*  Total wickets, economy-rate, strike-rate and best bowling figure
    for every bowler (Snowflake dialect)                                   */

WITH balls_per_bowler AS (          -- total balls delivered
    SELECT  "bowler",
            COUNT(*) AS "balls_bowled"
    FROM    IPL.IPL.BALL_BY_BALL
    GROUP BY "bowler"
),

runs_per_bowler AS (                -- runs conceded off the bat
    SELECT  bb."bowler",
            SUM( COALESCE(bs."runs_scored",0) ) AS "runs_off_bat"
    FROM    IPL.IPL.BALL_BY_BALL      bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED  bs
           ON bs."match_id"   = bb."match_id"
          AND bs."innings_no" = bb."innings_no"
          AND bs."over_id"    = bb."over_id"
          AND bs."ball_id"    = bb."ball_id"
    GROUP BY bb."bowler"
),

wickets_per_bowler AS (             -- wickets credited to bowler
    SELECT  b."bowler",
            COUNT(*) AS "wickets"
    FROM    IPL.IPL.WICKET_TAKEN   w
    JOIN    IPL.IPL.BALL_BY_BALL   b
           ON b."match_id"   = w."match_id"
          AND b."innings_no" = w."innings_no"
          AND b."over_id"    = w."over_id"
          AND b."ball_id"    = w."ball_id"
    WHERE   LOWER(w."kind_out") NOT IN ('run out', 'retired hurt', 'obstructing the field')
    GROUP BY b."bowler"
),

/* ----  Figures at match level (needed for “best” spell) ---------------- */
match_runs AS (
    SELECT  bb."bowler",
            bb."match_id",
            SUM( COALESCE(bs."runs_scored",0) ) AS "match_runs"
    FROM    IPL.IPL.BALL_BY_BALL     bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON bs."match_id"   = bb."match_id"
          AND bs."innings_no" = bb."innings_no"
          AND bs."over_id"    = bb."over_id"
          AND bs."ball_id"    = bb."ball_id"
    GROUP BY bb."bowler", bb."match_id"
),

match_wkts AS (
    SELECT  b."bowler",
            w."match_id",
            COUNT(*) AS "match_wkts"
    FROM    IPL.IPL.WICKET_TAKEN  w
    JOIN    IPL.IPL.BALL_BY_BALL  b
           ON b."match_id"   = w."match_id"
          AND b."innings_no" = w."innings_no"
          AND b."over_id"    = w."over_id"
          AND b."ball_id"    = w."ball_id"
    WHERE   LOWER(w."kind_out") NOT IN ('run out', 'retired hurt', 'obstructing the field')
    GROUP BY b."bowler", w."match_id"
),

best_spell AS (                      -- pick best match per bowler
    SELECT  mw."bowler",
            CONCAT(mw."match_wkts",'-',mr."match_runs") AS "best_bowling",
            ROW_NUMBER() OVER (PARTITION BY mw."bowler"
                                ORDER BY mw."match_wkts" DESC, mr."match_runs" ASC) AS rn
    FROM    match_wkts mw
    JOIN    match_runs mr
           ON mr."bowler"   = mw."bowler"
          AND mr."match_id" = mw."match_id"
)

/* ------------------------  Final output  ------------------------------- */
SELECT  bpb."bowler",
        COALESCE(wpb."wickets",0)                                             AS "total_wickets",
        ROUND( COALESCE(rpb."runs_off_bat",0) * 6.0 /
               NULLIF(bpb."balls_bowled",0) , 4)                              AS "economy_rate",
        ROUND( bpb."balls_bowled" * 1.0 /
               NULLIF(wpb."wickets",0) , 4)                                   AS "strike_rate",
        bs."best_bowling"
FROM    balls_per_bowler   bpb
LEFT JOIN runs_per_bowler  rpb ON rpb."bowler" = bpb."bowler"
LEFT JOIN wickets_per_bowler wpb ON wpb."bowler" = bpb."bowler"
LEFT JOIN best_spell        bs  ON bs."bowler"  = bpb."bowler" AND bs.rn = 1
ORDER BY "total_wickets" DESC NULLS LAST,
         "economy_rate"  ASC  NULLS LAST;