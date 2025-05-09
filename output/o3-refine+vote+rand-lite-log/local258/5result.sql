WITH legal_balls AS (
    /* Only those deliveries that count in an over
       – wides / no‑balls are removed                        */
    SELECT  bb.match_id ,
            bb.over_id ,
            bb.ball_id ,
            bb.innings_no ,
            bb.bowler
    FROM    ball_by_ball bb
    LEFT JOIN extra_runs er
           ON er.match_id  = bb.match_id
          AND er.over_id   = bb.over_id
          AND er.ball_id   = bb.ball_id
          AND er.innings_no= bb.innings_no
    WHERE   er.extra_type IS NULL
        OR (LOWER(er.extra_type) NOT LIKE 'wide%'   -- keep legal balls
            AND LOWER(er.extra_type) NOT LIKE 'noball%')
),
/* add runs off the bat and, when relevant, a wicket flag
   (run‑outs, retired‑hurt, etc. are NOT credited)           */
ball_details AS (
    SELECT  lb.bowler ,
            lb.match_id ,
            COALESCE(bs.runs_scored,0)                                       AS runs_scored ,
            CASE WHEN wt.match_id IS NOT NULL THEN 1 ELSE 0 END              AS wicket_flag
    FROM    legal_balls lb
    LEFT JOIN batsman_scored bs
           ON bs.match_id  = lb.match_id
          AND bs.over_id   = lb.over_id
          AND bs.ball_id   = lb.ball_id
          AND bs.innings_no= lb.innings_no
    LEFT JOIN wicket_taken wt
           ON wt.match_id  = lb.match_id
          AND wt.over_id   = lb.over_id
          AND wt.ball_id   = lb.ball_id
          AND wt.innings_no= lb.innings_no
          AND LOWER(wt.kind_out) NOT LIKE '%run out%'
          AND LOWER(wt.kind_out) NOT LIKE '%runout%'
          AND LOWER(wt.kind_out) NOT LIKE '%retired%'
          AND LOWER(wt.kind_out) NOT LIKE '%obstruct%'
),
/* career figures                                            */
bowler_agg AS (
    SELECT  bowler ,
            COUNT(*)                             AS legal_balls ,
            SUM(runs_scored)                     AS runs_conceded ,
            SUM(wicket_flag)                     AS wickets
    FROM    ball_details
    GROUP BY bowler
),
/* figures for every bowler in every match – needed
   to pick “best bowling”                                   */
match_stats AS (
    SELECT  bowler ,
            match_id ,
            SUM(runs_scored)   AS runs_in_match ,
            SUM(wicket_flag)   AS wickets_in_match
    FROM    ball_details
    GROUP BY bowler , match_id
),
/* choose the match with
   – most wickets
   – then least runs
   – then lowest match_id                                    */
best_bowling_per_bowler AS (
    SELECT  bowler ,
            printf('%d-%d', wickets_in_match, runs_in_match) AS best_bowling
    FROM   (
        SELECT  ms.* ,
                ROW_NUMBER() OVER (PARTITION BY bowler
                                   ORDER BY wickets_in_match DESC ,
                                            runs_in_match    ASC  ,
                                            match_id         ASC) AS rn
        FROM    match_stats ms
    )
    WHERE   rn = 1
)
/* final report                                              */
SELECT  p.player_name                                   AS bowler_name ,
        ba.wickets                                      AS total_wickets ,
        ROUND(
              CASE WHEN ba.legal_balls = 0
                   THEN NULL
                   ELSE CAST(ba.runs_conceded AS REAL) / (ba.legal_balls/6.0)
              END , 4)                                  AS economy_rate ,
        ROUND(
              CASE WHEN ba.wickets = 0
                   THEN NULL
                   ELSE ba.legal_balls*1.0 / ba.wickets
              END , 4)                                  AS strike_rate ,
        bbp.best_bowling
FROM    bowler_agg                ba
JOIN    player                    p   ON p.player_id = ba.bowler
LEFT JOIN best_bowling_per_bowler bbp ON bbp.bowler  = ba.bowler
ORDER BY total_wickets DESC , bowler_name;