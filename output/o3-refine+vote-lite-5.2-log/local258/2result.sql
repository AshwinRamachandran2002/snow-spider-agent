WITH ball_stats AS (
    /* 1.  Numbers for every bowler in every match */
    SELECT
        b.match_id,
        b.bowler                    AS bowler_id,
        /* runs off the bat (ignore all extras)                           */
        SUM( COALESCE(bs.runs_scored,0) )                                           AS runs_off_bat,
        /* legal‑deliveries = balls that are NOT wides / no‑balls          */
        SUM(
            CASE
                WHEN er.extra_type IS NOT NULL
                     AND lower(er.extra_type) IN ('wide','wides','noball','noballs')
                THEN 0
                ELSE 1
            END
        )                                                                          AS legal_balls,
        /* wickets that are credited to a bowler (exclude run‑outs, etc.) */
        SUM(
            CASE
                WHEN w.player_out IS NOT NULL
                     AND lower(w.kind_out) NOT IN ('run out','runout',
                                                  'retired hurt',
                                                  'obstructed the field')
                THEN 1
                ELSE 0
            END
        )                                                                          AS wickets
    FROM ball_by_ball  b
    LEFT JOIN batsman_scored bs
           ON b.match_id  = bs.match_id
          AND b.over_id   = bs.over_id
          AND b.ball_id   = bs.ball_id
          AND b.innings_no= bs.innings_no
    LEFT JOIN extra_runs     er
           ON b.match_id  = er.match_id
          AND b.over_id   = er.over_id
          AND b.ball_id   = er.ball_id
          AND b.innings_no= er.innings_no
    LEFT JOIN wicket_taken   w
           ON b.match_id  = w.match_id
          AND b.over_id   = w.over_id
          AND b.ball_id   = w.ball_id
          AND b.innings_no= w.innings_no
    GROUP BY b.match_id, b.bowler
),
/* 2.  Career aggregates for every bowler */
bowler_totals AS (
    SELECT
        bowler_id,
        SUM(runs_off_bat)  AS total_runs,
        SUM(legal_balls)   AS total_legal_balls,
        SUM(wickets)       AS total_wickets
    FROM ball_stats
    GROUP BY bowler_id
),
/* 3.  Work out each bowler’s best match – most wickets, tie‑break by fewest runs */
best_match_ranked AS (
    SELECT
        bowler_id,
        match_id,
        wickets,
        runs_off_bat,
        ROW_NUMBER() OVER (
            PARTITION BY bowler_id
            ORDER BY wickets DESC, runs_off_bat ASC
        ) AS rn
    FROM ball_stats
),
best_match AS (
    SELECT
        bowler_id,
        wickets  AS best_wkts,
        runs_off_bat AS best_runs
    FROM best_match_ranked
    WHERE rn = 1
)
/* 4.  Final report */
SELECT
    p.player_name                               AS bowler,
    bt.total_wickets,
    ROUND( (bt.total_runs * 6.0) / NULLIF(bt.total_legal_balls,0), 4 ) AS economy_rate,
    ROUND( bt.total_legal_balls / NULLIF(bt.total_wickets,0),      4 ) AS strike_rate,
    best_match.best_wkts || '-' || best_match.best_runs             AS best_bowling
FROM bowler_totals bt
JOIN player       p  ON p.player_id  = bt.bowler_id
JOIN best_match   ON best_match.bowler_id = bt.bowler_id
ORDER BY bt.total_wickets DESC,
         economy_rate       ASC,
         p.player_name;