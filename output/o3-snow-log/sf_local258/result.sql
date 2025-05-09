/*  Comprehensive bowling summary for every bowler
    – total wickets (excluding run-outs, retired hurt, obstructing-field)
    – economy rate    :  runs-off-the-bat ÷ overs bowled
    – strike  rate    :  balls bowled ÷ wickets
    – best match figure formatted “wkts-runs” (most wickets, then fewest runs)  */

WITH                                                          -- 1)  all wickets that count for the bowler
valid_wkts AS (           
    SELECT  bb."bowler",
            bb."match_id",
            COUNT(*)               AS "wkts_in_match"
    FROM   IPL.IPL.WICKET_TAKEN wt
    JOIN   IPL.IPL.BALL_BY_BALL bb
           ON  bb."match_id"   = wt."match_id"
           AND bb."over_id"    = wt."over_id"
           AND bb."ball_id"    = wt."ball_id"
           AND bb."innings_no" = wt."innings_no"
    WHERE  wt."kind_out" NOT ILIKE '%run%out%'          -- exclude run-outs
      AND  wt."kind_out" NOT IN ('retired hurt',        -- and other non-bowler dismissals
                                 'obstructing the field')
    GROUP  BY bb."bowler", bb."match_id"
),                                                          -- 2)  total wickets per bowler
total_wkts AS (
    SELECT  "bowler",
            SUM("wkts_in_match")   AS "total_wkts"
    FROM    valid_wkts
    GROUP   BY "bowler"
),                                                          -- 3)  runs off the bat conceded by each bowler
runs_off_bat AS (
    SELECT  bb."bowler",
            SUM(bs."runs_scored")  AS "runs_off_bat"
    FROM    IPL.IPL.BALL_BY_BALL   bb
    JOIN    IPL.IPL.BATSMAN_SCORED bs
           ON  bs."match_id"   = bb."match_id"
           AND bs."over_id"    = bb."over_id"
           AND bs."ball_id"    = bb."ball_id"
           AND bs."innings_no" = bb."innings_no"
    GROUP   BY bb."bowler"
),                                                          -- 4)  legal balls bowled per bowler
balls_bowled AS (
    SELECT  "bowler",
            COUNT(*)              AS "balls"
    FROM    IPL.IPL.BALL_BY_BALL
    GROUP   BY "bowler"
),                                                          -- 5)  best bowling performance in any single match
best_match AS (
    /*  First, attach runs-conceded for every (bowler, match) pair  */
    WITH match_runs AS (
         SELECT  bb."bowler",
                 bb."match_id",
                 SUM(bs."runs_scored")  AS "runs_in_match"
         FROM    IPL.IPL.BALL_BY_BALL   bb
         JOIN    IPL.IPL.BATSMAN_SCORED bs
                ON  bs."match_id"   = bb."match_id"
                AND bs."over_id"    = bb."over_id"
                AND bs."ball_id"    = bb."ball_id"
                AND bs."innings_no" = bb."innings_no"
         GROUP   BY bb."bowler", bb."match_id"
    )
    SELECT  v."bowler",
            CONCAT(v."wkts_in_match", '-', mr."runs_in_match")  AS "best_figure"
    FROM    valid_wkts v
    JOIN    match_runs mr
           ON  mr."bowler"   = v."bowler"
           AND mr."match_id" = v."match_id"
    QUALIFY ROW_NUMBER() OVER (PARTITION BY v."bowler"
                               ORDER BY v."wkts_in_match" DESC,
                                        mr."runs_in_match") = 1
)
SELECT  p."player_name",
        tw."total_wkts"                                              AS "total_wickets",
        ROUND( ro."runs_off_bat" / (bb."balls" / 6.0), 2)            AS "economy_rate",
        ROUND( bb."balls" / NULLIF(tw."total_wkts",0), 2)            AS "strike_rate",
        bm."best_figure"
FROM        balls_bowled  bb
JOIN        runs_off_bat  ro  ON ro."bowler"   = bb."bowler"
JOIN        total_wkts    tw  ON tw."bowler"   = bb."bowler"
JOIN        best_match    bm  ON bm."bowler"   = bb."bowler"
JOIN        IPL.IPL.PLAYER p   ON p."player_id" = bb."bowler"
ORDER BY    tw."total_wkts" DESC NULLS LAST;