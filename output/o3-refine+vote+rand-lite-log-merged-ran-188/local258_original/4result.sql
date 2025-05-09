WITH legal_deliveries AS (
    /* keep only legitimate balls – remove wides & no‑balls                       */
    SELECT  b.*
    FROM    ball_by_ball  b
    LEFT JOIN extra_runs  e
           ON  e.match_id   = b.match_id
           AND e.over_id    = b.over_id
           AND e.ball_id    = b.ball_id
           AND e.innings_no = b.innings_no
           AND e.extra_type IN ('wides' , 'noballs')
    WHERE   e.extra_type IS NULL
),
delivery_runs AS (
    /* balls bowled and runs off the bat conceded (ignore every extra)            */
    SELECT  ld.bowler              AS player_id,
            ld.match_id,
            COUNT(*)               AS balls,
            COALESCE(SUM(s.runs_scored),0) AS runs_conceded
    FROM    legal_deliveries ld
    LEFT  JOIN batsman_scored s
           ON  s.match_id   = ld.match_id
           AND s.over_id    = ld.over_id
           AND s.ball_id    = ld.ball_id
           AND s.innings_no = ld.innings_no
    GROUP  BY ld.bowler , ld.match_id
),
wickets AS (
    /* wickets credited to bowler – exclude run‑outs and similar                  */
    SELECT  ld.bowler  AS player_id,
            w.match_id,
            COUNT(*)   AS wickets
    FROM    legal_deliveries ld
    JOIN    wicket_taken  w
           ON  w.match_id   = ld.match_id
           AND w.over_id    = ld.over_id
           AND w.ball_id    = ld.ball_id
           AND w.innings_no = ld.innings_no
    WHERE   LOWER(w.kind_out) NOT IN ('run out',
                                      'retired hurt',
                                      'retired out',
                                      'obstructed field')
    GROUP  BY ld.bowler , w.match_id
),
overall AS (
    /* career aggregates for every bowler                                         */
    SELECT  dr.player_id,
            SUM(dr.balls)               AS total_balls,
            SUM(dr.runs_conceded)       AS total_runs,
            COALESCE(SUM(w.wickets),0)  AS total_wkts
    FROM    delivery_runs dr
    LEFT  JOIN wickets w
           ON  w.player_id = dr.player_id
           AND w.match_id  = dr.match_id
    GROUP  BY dr.player_id
),
best_match AS (
    /* find each bowler’s best match (most wkts, then least runs)                 */
    SELECT  dr.player_id,
            dr.match_id,
            COALESCE(w.wickets,0) AS wkts,
            dr.runs_conceded      AS runs,
            ROW_NUMBER() OVER (PARTITION BY dr.player_id
                               ORDER BY COALESCE(w.wickets,0) DESC,
                                        dr.runs_conceded ASC) AS rn
    FROM    delivery_runs dr
    LEFT  JOIN wickets w
           ON  w.player_id = dr.player_id
           AND w.match_id  = dr.match_id
)
SELECT  p.player_name,
        o.total_wkts                                AS total_wickets,
        ROUND( (o.total_runs * 6.0) / o.total_balls , 4)          AS economy_rate,
        CASE WHEN o.total_wkts > 0
             THEN ROUND( o.total_balls * 1.0 / o.total_wkts , 4)
        END                                            AS strike_rate,
        (SELECT bm.wkts || '-' || bm.runs
         FROM   best_match bm
         WHERE  bm.player_id = o.player_id
         AND    bm.rn = 1)                             AS best_bowling
FROM    overall  o
JOIN    player   p  ON p.player_id = o.player_id
ORDER BY o.total_wkts DESC,
         p.player_name;