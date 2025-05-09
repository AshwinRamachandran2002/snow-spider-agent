WITH wicket_filtered AS (
    /* Wickets that are credited to the bowler
       (exclude run‑outs and other non‑bowler dismissals) */
    SELECT match_id,
           over_id,
           ball_id
    FROM   wicket_taken
    WHERE  LOWER(kind_out) NOT IN ('run out',
                                   'retired hurt',
                                   'obstructing field',
                                   'obstructed the field')
),
extra_agg AS (
    /* Detect if a delivery is a wide or a no‑ball                */
    SELECT match_id,
           over_id,
           ball_id,
           MAX(CASE
                   WHEN LOWER(extra_type) IN ('wides','noballs')
                   THEN 1 ELSE 0
               END) AS is_wide_nb
    FROM   extra_runs
    GROUP  BY match_id, over_id, ball_id
),
deliveries AS (
    /* Every ball bowled, with runs off the bat,
       legality of the delivery, and whether it produced a wicket */
    SELECT b.match_id,
           b.bowler,                          -- the bowler (player_id)
           b.over_id,
           b.ball_id,
           COALESCE(bs.runs_scored,0)                AS runs_scored,
           CASE WHEN COALESCE(e.is_wide_nb,0)=1
                THEN 0 ELSE 1 END                   AS legal_ball,
           CASE WHEN wf.match_id IS NULL
                THEN 0 ELSE 1 END                   AS is_wicket
    FROM   ball_by_ball b
    LEFT   JOIN batsman_scored  bs
           ON  bs.match_id  = b.match_id
           AND bs.over_id   = b.over_id
           AND bs.ball_id   = b.ball_id
           AND bs.innings_no= b.innings_no
    LEFT   JOIN extra_agg      e
           ON  e.match_id  = b.match_id
           AND e.over_id   = b.over_id
           AND e.ball_id   = b.ball_id
    LEFT   JOIN wicket_filtered wf
           ON  wf.match_id = b.match_id
           AND wf.over_id  = b.over_id
           AND wf.ball_id  = b.ball_id
),
/* ------------------------------------------------------------ */
bowler_totals AS (
    /* Career aggregates for each bowler */
    SELECT bowler,
           SUM(is_wicket)          AS total_wkts,
           SUM(runs_scored)        AS runs_conceded,
           SUM(legal_ball)         AS legal_balls
    FROM   deliveries
    GROUP  BY bowler
),
bowler_match AS (
    /* Figures per bowler per match – needed for “best bowling” */
    SELECT bowler,
           match_id,
           SUM(is_wicket)   AS wkts_in_match,
           SUM(runs_scored) AS runs_in_match
    FROM   deliveries
    GROUP  BY bowler, match_id
),
best_performance AS (
    /* Rank each bowler’s match performances, preferring
       most wickets, then fewest runs, then earliest match    */
    SELECT bowler,
           wkts_in_match,
           runs_in_match,
           match_id,
           ROW_NUMBER() OVER (PARTITION BY bowler
                              ORDER BY wkts_in_match DESC,
                                       runs_in_match ASC,
                                       match_id          ) AS rn
    FROM   bowler_match
),
best AS (
    /* Keep only the best performance for every bowler */
    SELECT bowler,
           wkts_in_match || '-' || runs_in_match AS best_figures
    FROM   best_performance
    WHERE  rn = 1
)
/* -------------------  FINAL RESULT  ------------------------- */
SELECT  p.player_name                    AS bowler_name,
        bt.total_wkts                   AS wickets,
        ROUND(bt.runs_conceded * 6.0
              / NULLIF(bt.legal_balls,0), 4)     AS economy_rate,
        ROUND(CASE 
                 WHEN bt.total_wkts = 0 
                 THEN NULL 
                 ELSE bt.legal_balls * 1.0 / bt.total_wkts 
              END, 4)                             AS strike_rate,
        b.best_figures                 AS best_bowling
FROM    bowler_totals bt
JOIN    player        p ON p.player_id = bt.bowler
LEFT    JOIN best     b ON b.bowler     = bt.bowler
ORDER BY wickets DESC,
         economy_rate ASC,
         bowler_name;