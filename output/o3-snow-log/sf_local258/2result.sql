/*--------------------------------------------------------------------
  Compute – for every bowler –
    • total wickets (excluding run-outs etc.)
    • economy rate (runs-off-bat ÷ overs of legal balls)
    • strike-rate  (balls per wicket)
    • best bowling figures in a single match   ‑-  “wkts-runs”
--------------------------------------------------------------------*/
WITH legal_deliveries AS (                /* keep only legal balls (no wides / no-balls) */
    SELECT  b."match_id",
            b."innings_no",
            b."over_id",
            b."ball_id",
            b."bowler"
    FROM    IPL.IPL.BALL_BY_BALL  b
    LEFT JOIN IPL.IPL.EXTRA_RUNS  e
           ON  b."match_id"  = e."match_id"
          AND b."innings_no" = e."innings_no"
          AND b."over_id"    = e."over_id"
          AND b."ball_id"    = e."ball_id"
    WHERE   e."extra_type" IS NULL
        OR  e."extra_type" NOT IN ('wides','noballs')
),

runs_balls AS (                          /* balls & runs (off the bat) per bowler */
    SELECT  ld."bowler",
            COUNT(*)              AS "legal_balls",
            SUM(bs."runs_scored") AS "runs_off_bat"
    FROM    legal_deliveries       ld
    JOIN    IPL.IPL.BATSMAN_SCORED bs
           ON  ld."match_id"  = bs."match_id"
          AND ld."innings_no" = bs."innings_no"
          AND ld."over_id"    = bs."over_id"
          AND ld."ball_id"    = bs."ball_id"
    GROUP BY ld."bowler"
),

wickets AS (                             /* wickets credited to the bowler */
    SELECT  b."bowler",
            COUNT(*)  AS "total_wkts"
    FROM    IPL.IPL.WICKET_TAKEN w
    JOIN    IPL.IPL.BALL_BY_BALL b
           ON  w."match_id"  = b."match_id"
          AND w."innings_no" = b."innings_no"
          AND w."over_id"    = b."over_id"
          AND w."ball_id"    = b."ball_id"
    WHERE   w."kind_out" NOT IN ('run out',
                                 'retired hurt',
                                 'retired',
                                 'obstructing the field')
    GROUP BY b."bowler"
),

best_bowling AS (                        /* best single-match figures */
    SELECT  s."bowler",
            TO_CHAR(s."wkts_in_match") || '-' || TO_CHAR(s."runs_in_match") AS "best_figures"
    FROM (
        SELECT  ld."bowler",
                ld."match_id",
                COUNT(DISTINCT CASE
                                  WHEN w."kind_out" NOT IN ('run out',
                                                            'retired hurt',
                                                            'retired',
                                                            'obstructing the field')
                                  THEN ld."ball_id"
                              END)                AS "wkts_in_match",
                SUM(bs."runs_scored")            AS "runs_in_match",
                ROW_NUMBER() OVER (PARTITION BY ld."bowler"
                                   ORDER BY 
                                         COUNT(DISTINCT CASE
                                                           WHEN w."kind_out" NOT IN ('run out',
                                                                                     'retired hurt',
                                                                                     'retired',
                                                                                     'obstructing the field')
                                                           THEN ld."ball_id"
                                                       END) DESC,
                                         SUM(bs."runs_scored")) AS "rn"
        FROM    legal_deliveries       ld
        JOIN    IPL.IPL.BATSMAN_SCORED bs
               ON  ld."match_id"  = bs."match_id"
              AND ld."innings_no" = bs."innings_no"
              AND ld."over_id"    = bs."over_id"
              AND ld."ball_id"    = bs."ball_id"
        LEFT JOIN IPL.IPL.WICKET_TAKEN w
               ON  ld."match_id"  = w."match_id"
              AND ld."innings_no" = w."innings_no"
              AND ld."over_id"    = w."over_id"
              AND ld."ball_id"    = w."ball_id"
        GROUP BY ld."bowler", ld."match_id"
    ) s
    WHERE s."rn" = 1
),

final AS (                               /* combine everything & compute metrics */
    SELECT  p."player_name"                              AS "bowler_name",
            w."bowler",
            w."total_wkts",
            rb."legal_balls",
            rb."runs_off_bat",
            bb."best_figures",
            (rb."runs_off_bat" / (rb."legal_balls" / 6.0))          AS "economy",
            (rb."legal_balls" / w."total_wkts")                     AS "strike_rate"
    FROM   wickets       w
    JOIN   runs_balls    rb  ON rb."bowler"   = w."bowler"
    JOIN   best_bowling  bb  ON bb."bowler"  = w."bowler"
    JOIN   IPL.IPL.PLAYER p   ON p."player_id" = w."bowler"
)

SELECT  "bowler_name",
        "bowler",
        "total_wkts",
        ROUND("economy",     2) AS "economy",
        ROUND("strike_rate", 2) AS "strike_rate",
        "best_figures"
FROM    final
ORDER BY "total_wkts" DESC NULLS LAST;