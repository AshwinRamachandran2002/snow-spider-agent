WITH deliveries AS (
    /* every legal delivery with runs off the bat */
    SELECT  bb.bowler,
            bb.match_id,
            bb.over_id,
            bb.ball_id,
            bs.runs_scored  AS runs_bat
    FROM    ball_by_ball  AS bb
    JOIN    batsman_scored AS bs
           ON bs.match_id = bb.match_id
          AND bs.over_id  = bb.over_id
          AND bs.ball_id  = bb.ball_id
),
bowler_totals AS (
    /* balls bowled & runs conceded (bat only) */
    SELECT  bowler,
            COUNT(*)               AS balls_bowled,
            SUM(runs_bat)          AS runs_conceded
    FROM    deliveries
    GROUP BY bowler
),
wickets_cte AS (
    /* wickets credited to the bowler */
    SELECT  bb.bowler,
            COUNT(*)               AS wickets
    FROM    wicket_taken  AS wt
    JOIN    ball_by_ball AS bb
           ON (bb.match_id, bb.over_id, bb.ball_id)
          = (wt.match_id, wt.over_id, wt.ball_id)
    WHERE   wt.kind_out NOT IN ('run out',
                                'retired hurt',
                                'obstructing the field')
    GROUP BY bb.bowler
),
match_figures AS (
    /* per-match wickets & runs for each bowler */
    SELECT  d.bowler,
            d.match_id,
            SUM(d.runs_bat)                                                    AS runs_in_match,
            SUM(CASE WHEN wt.kind_out NOT IN ('run out',
                                              'retired hurt',
                                              'obstructing the field')
                     THEN 1 ELSE 0 END)                                        AS wkts_in_match
    FROM    deliveries AS d
    LEFT JOIN wicket_taken AS wt
           ON (wt.match_id, wt.over_id, wt.ball_id)
          = (d.match_id, d.over_id, d.ball_id)
    GROUP BY d.bowler, d.match_id
),
best_figures AS (
    /* pick best match for every bowler: most wkts, then fewest runs */
    SELECT  mf.bowler,
            printf('%d-%d', mf.wkts_in_match, mf.runs_in_match) AS best_figures
    FROM   (
            SELECT  mf.*,
                    ROW_NUMBER() OVER (PARTITION BY bowler
                                        ORDER BY wkts_in_match DESC,
                                                 runs_in_match ASC) AS rn
            FROM    match_figures mf
           ) mf
    WHERE  rn = 1
)
SELECT  p.player_name,
        w.wickets,
        ROUND(bt.runs_conceded * 1.0 / (bt.balls_bowled / 6.0), 4) AS economy_rate,
        ROUND(bt.balls_bowled * 1.0 / w.wickets,                  4) AS strike_rate,
        bf.best_figures
FROM        bowler_totals  AS bt
JOIN        wickets_cte    AS w   ON w.bowler   = bt.bowler
JOIN        best_figures   AS bf  ON bf.bowler  = bt.bowler
JOIN        player         AS p   ON p.player_id= bt.bowler
ORDER BY    w.wickets DESC, economy_rate;