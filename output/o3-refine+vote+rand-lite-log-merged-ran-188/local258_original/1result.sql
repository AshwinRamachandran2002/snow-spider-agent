WITH legal_balls AS (
    /* every delivery bowled with runs off the bat
       and a flag that it is a legal ball (i.e. not a wide / no‑ball)        */
    SELECT  bb.match_id,
            bb.over_id,
            bb.ball_id,
            bb.bowler                         AS bowler_id,
            COALESCE(bs.runs_scored ,0)       AS runs_off_bat,
            CASE 
                 WHEN er.extra_type IN ('wides','no-balls') THEN 0 
                 ELSE 1 
            END                               AS legal_ball
    FROM   ball_by_ball        bb
    LEFT JOIN batsman_scored   bs
           ON  bs.match_id   = bb.match_id 
           AND bs.over_id    = bb.over_id
           AND bs.ball_id    = bb.ball_id
           AND bs.innings_no = bb.innings_no
    LEFT JOIN extra_runs       er
           ON  er.match_id   = bb.match_id 
           AND er.over_id    = bb.over_id
           AND er.ball_id    = bb.ball_id
           AND er.innings_no = bb.innings_no
),
wickets AS (
    /* wickets that are credited to the bowler                                */
    SELECT  bb.match_id,
            bb.over_id,
            bb.ball_id,
            bb.bowler          AS bowler_id
    FROM    wicket_taken  wt
    JOIN    ball_by_ball bb
           ON  bb.match_id   = wt.match_id
           AND bb.over_id    = wt.over_id
           AND bb.ball_id    = wt.ball_id
           AND bb.innings_no = wt.innings_no
    WHERE   lower(wt.kind_out) NOT IN ('run out',
                                       'retired hurt',
                                       'obstructing the field',
                                       'retired')
),
bowler_match AS (
    /* per‑bowler, per‑match numbers                                           */
    SELECT  lb.bowler_id,
            lb.match_id,
            SUM(lb.runs_off_bat)          AS runs_conceded,
            SUM(lb.legal_ball)            AS legal_balls,
            COUNT(w.bowler_id)            AS wickets
    FROM    legal_balls lb
    LEFT JOIN wickets     w
           ON w.match_id = lb.match_id
          AND w.over_id  = lb.over_id
          AND w.ball_id  = lb.ball_id
    GROUP BY lb.bowler_id, lb.match_id
),
bowler_totals AS (
    /* career aggregates for every bowler                                      */
    SELECT  bowler_id,
            SUM(wickets)           AS total_wkts,
            SUM(runs_conceded)     AS total_runs,
            SUM(legal_balls)       AS total_balls
    FROM    bowler_match
    GROUP BY bowler_id
),
best_performance AS (
    /* find the best single‑match return for each bowler                       */
    SELECT  bowler_id,
            printf('%d-%d', wickets, runs_conceded) AS best_figures,
            ROW_NUMBER() OVER (PARTITION BY bowler_id
                               ORDER BY wickets DESC,
                                        runs_conceded ASC,
                                        match_id)   AS rn
    FROM    bowler_match
)
SELECT  p.player_id,
        p.player_name,
        bt.total_wkts                                         AS total_wickets,
        ROUND(bt.total_runs * 6.0 / NULLIF(bt.total_balls,0), 4) AS economy_rate,
        ROUND(bt.total_balls * 1.0 / NULLIF(bt.total_wkts ,0), 4) AS strike_rate,
        bp.best_figures                                       AS best_bowling
FROM    bowler_totals  bt
JOIN    player         p  ON p.player_id = bt.bowler_id
JOIN    best_performance bp ON bp.bowler_id = bt.bowler_id AND bp.rn = 1
ORDER BY bt.total_wkts DESC,
         economy_rate   ASC,
         p.player_name;