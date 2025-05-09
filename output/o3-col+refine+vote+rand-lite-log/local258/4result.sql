WITH per_ball AS (
    SELECT
        bb.bowler,
        bb.match_id,
        bb.innings_no,
        bb.over_id,
        bb.ball_id,
        COALESCE(bs.runs_scored,0) AS runs_off_bat,
        CASE
            WHEN wt.kind_out IS NOT NULL
                 AND wt.kind_out NOT LIKE '%run%'          -- exclude run-outs
                 AND wt.kind_out NOT IN ('retired hurt',   -- and any other
                                          'obstructing the field') 
            THEN 1 ELSE 0
        END                                             AS wicket_flag
    FROM ball_by_ball AS bb
    LEFT JOIN batsman_scored AS bs
           ON  bb.match_id   = bs.match_id
          AND bb.over_id     = bs.over_id
          AND bb.ball_id     = bs.ball_id
          AND bb.innings_no  = bs.innings_no
    LEFT JOIN wicket_taken  AS wt
           ON  bb.match_id   = wt.match_id
          AND bb.over_id     = wt.over_id
          AND bb.ball_id     = wt.ball_id
          AND bb.innings_no  = wt.innings_no
),
bowler_totals AS (      -- career aggregates
    SELECT
        bowler,
        COUNT(*)                      AS total_balls,
        SUM(runs_off_bat)             AS total_runs,
        SUM(wicket_flag)              AS total_wkts
    FROM per_ball
    GROUP BY bowler
),
per_match AS (          -- figures per match for every bowler
    SELECT
        bowler,
        match_id,
        SUM(wicket_flag)  AS wkts_in_match,
        SUM(runs_off_bat) AS runs_in_match
    FROM per_ball
    GROUP BY bowler, match_id
),
best_match AS (         -- best bowling: most wkts, then fewest runs
    SELECT  pm1.bowler,
            pm1.wkts_in_match,
            pm1.runs_in_match
    FROM    per_match pm1
    LEFT JOIN per_match pm2
           ON pm1.bowler = pm2.bowler
          AND (pm2.wkts_in_match  > pm1.wkts_in_match
               OR (pm2.wkts_in_match = pm1.wkts_in_match
                   AND pm2.runs_in_match < pm1.runs_in_match))
    WHERE pm2.bowler IS NULL        -- keep only the best row for each bowler
)
SELECT
       bt.bowler                                   AS bowler_id,
       bt.total_wkts                               AS total_wickets,
       ROUND(bt.total_runs / (bt.total_balls/6.0), 4)          AS economy_rate,
       ROUND(CASE WHEN bt.total_wkts>0 
                  THEN bt.total_balls*1.0/bt.total_wkts 
             END, 4)                               AS strike_rate,
       printf('%d-%d', bm.wkts_in_match, bm.runs_in_match)     AS best_bowling
FROM   bowler_totals  bt
LEFT JOIN best_match bm ON bt.bowler = bm.bowler
ORDER BY bt.bowler;