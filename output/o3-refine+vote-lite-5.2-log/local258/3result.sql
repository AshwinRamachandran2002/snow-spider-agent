WITH ball_details AS (
    /* every delivery bowled by a known bowler */
    SELECT  b.bowler,
            b.match_id,
            1                                           AS ball_flag,                     -- one ball
            COALESCE(bs.runs_scored ,0)                 AS runs_off_bat,                  -- ignore wides / no‑balls (they live in extra_runs)
            CASE                                        /* wicket that belongs to bowler */
                 WHEN w.kind_out IS NOT NULL
                      AND w.kind_out NOT IN ('run out',
                                             'retired hurt',
                                             'retired out',
                                             'obstructing the field')
                 THEN 1
                 ELSE 0
            END                                         AS wicket_flag
    FROM   ball_by_ball      AS b
    LEFT   JOIN batsman_scored AS bs
           ON  bs.match_id   = b.match_id
           AND bs.over_id    = b.over_id
           AND bs.ball_id    = b.ball_id
           AND bs.innings_no = b.innings_no
    LEFT   JOIN wicket_taken   AS w
           ON  w.match_id   = b.match_id
           AND w.over_id    = b.over_id
           AND w.ball_id    = b.ball_id
           AND w.innings_no = b.innings_no
    WHERE  b.bowler IS NOT NULL                       -- keep only legitimate bowlers
),
per_match_stats AS (
    /* runs / balls / wickets for every bowler in every match */
    SELECT  bowler,
            match_id,
            SUM(ball_flag)            AS balls,
            SUM(runs_off_bat)         AS runs_conceded,
            SUM(wicket_flag)          AS wickets_taken
    FROM    ball_details
    GROUP BY bowler, match_id
),
overall AS (
    /* career totals for each bowler */
    SELECT  bowler,
            SUM(balls)            AS total_balls,
            SUM(runs_conceded)    AS total_runs,
            SUM(wickets_taken)    AS total_wickets
    FROM    per_match_stats
    GROUP BY bowler
),
best_match AS (
    /* pick the match with most wickets (ties → fewer runs) */
    SELECT  bowler,
            match_id,
            wickets_taken,
            runs_conceded,
            ROW_NUMBER() OVER (PARTITION BY bowler
                               ORDER BY wickets_taken DESC,
                                        runs_conceded ASC)   AS rn
    FROM    per_match_stats
),
best_by_bowler AS (
    SELECT  bowler,
            printf('%d-%d',wickets_taken,runs_conceded) AS best_figures
    FROM    best_match
    WHERE   rn = 1
)
SELECT  p.player_name                        AS bowler_name,
        o.total_wickets,
        ROUND(o.total_runs / (o.total_balls/6.0),4)   AS economy_rate,
        CASE WHEN o.total_wickets = 0
             THEN NULL
             ELSE ROUND(o.total_balls*1.0 / o.total_wickets,4)
        END                                           AS strike_rate,
        b.best_figures
FROM    overall            AS o
JOIN    best_by_bowler     AS b  ON o.bowler = b.bowler
JOIN    player             AS p  ON p.player_id = o.bowler
ORDER BY o.total_wickets DESC,
         p.player_name;