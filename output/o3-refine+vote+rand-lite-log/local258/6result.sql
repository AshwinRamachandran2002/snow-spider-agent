WITH delivery AS (
    /*  every ball a bowler delivers  */
    SELECT  b.match_id ,
            b.over_id ,
            b.ball_id ,
            b.innings_no ,
            b.bowler ,
            COALESCE(bs.runs_scored ,0)                                           AS bat_runs ,          -- runs off the bat
            CASE                                                                  -- legal‑ball flag
                 WHEN er.extra_type IN ('wides','noballs') THEN 0
                 ELSE 1
            END                                                                  AS is_legal_ball
    FROM   ball_by_ball      b
    LEFT JOIN batsman_scored bs
           ON bs.match_id   = b.match_id
          AND bs.over_id    = b.over_id
          AND bs.ball_id    = b.ball_id
          AND bs.innings_no = b.innings_no
    LEFT JOIN extra_runs     er
           ON er.match_id   = b.match_id
          AND er.over_id    = b.over_id
          AND er.ball_id    = b.ball_id
          AND er.innings_no = b.innings_no
),
/*  overall runs & (legal) balls for every bowler  */
bowler_summary AS (
    SELECT bowler ,
           SUM(is_legal_ball)                      AS legal_balls ,
           SUM(bat_runs)                          AS runs_conceded
    FROM   delivery
    GROUP BY bowler
),
/*  per‑match runs & balls – used for “best figures”  */
bowler_match_summary AS (
    SELECT bowler ,
           match_id ,
           SUM(is_legal_ball)                      AS legal_balls_match ,
           SUM(bat_runs)                          AS runs_conceded_match
    FROM   delivery
    GROUP BY bowler , match_id
),
/*  total wickets credited to every bowler                */
wickets AS (
    SELECT  bb.bowler ,
            COUNT(*)                               AS wickets
    FROM    wicket_taken       w
    JOIN    ball_by_ball       bb
           ON bb.match_id   = w.match_id
          AND bb.over_id    = w.over_id
          AND bb.ball_id    = w.ball_id
          AND bb.innings_no = w.innings_no
    /*  remove dismissals not credited to the bowler  */
    WHERE lower(w.kind_out) NOT LIKE '%run out%'
    GROUP BY bb.bowler
),
/*  wickets per match – for best bowling analysis         */
wickets_match AS (
    SELECT  bb.bowler ,
            bb.match_id ,
            COUNT(*)                               AS wickets_match
    FROM    wicket_taken       w
    JOIN    ball_by_ball       bb
           ON bb.match_id   = w.match_id
          AND bb.over_id    = w.over_id
          AND bb.ball_id    = w.ball_id
          AND bb.innings_no = w.innings_no
    WHERE lower(w.kind_out) NOT LIKE '%run out%'
    GROUP BY bb.bowler , bb.match_id
),
/*  pick each bowler’s best match: most wickets, then fewest runs  */
best_performance AS (
    SELECT  wm.bowler ,
            wm.match_id ,
            wm.wickets_match ,
            bms.runs_conceded_match ,
            ROW_NUMBER() OVER (PARTITION BY wm.bowler
                               ORDER BY wm.wickets_match DESC ,
                                        bms.runs_conceded_match ASC) AS rn
    FROM    wickets_match        wm
    JOIN    bowler_match_summary bms
           ON  wm.bowler   = bms.bowler
          AND wm.match_id  = bms.match_id
)
SELECT  p.player_name                                               AS bowler_name ,
        COALESCE(wk.wickets ,0)                                     AS total_wickets ,
        ROUND(
              CASE WHEN bs.legal_balls = 0
                   THEN NULL
                   ELSE (bs.runs_conceded * 6.0) / bs.legal_balls   -- economy  = runs / overs
              END ,4)                                               AS economy_rate ,
        ROUND(
              CASE WHEN COALESCE(wk.wickets ,0) = 0
                   THEN NULL
                   ELSE (bs.legal_balls * 1.0) / wk.wickets         -- strike rate = balls / wicket
              END ,4)                                               AS strike_rate ,
        printf('%d-%d',
               COALESCE(bp.wickets_match ,0),
               COALESCE(bp.runs_conceded_match ,0))                 AS best_bowling_figures
FROM        bowler_summary   bs
LEFT  JOIN  wickets          wk   ON wk.bowler = bs.bowler
LEFT  JOIN  best_performance bp   ON bp.bowler = bs.bowler
                                   AND bp.rn = 1
JOIN        player           p    ON p.player_id = bs.bowler
ORDER BY    total_wickets DESC ,
            p.player_name;