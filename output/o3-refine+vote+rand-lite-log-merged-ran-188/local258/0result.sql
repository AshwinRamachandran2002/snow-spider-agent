WITH delivery_stats AS (          -- figures for every bowler in every match
    SELECT
        bb."match_id",
        bb."bowler"                               AS bowler_id,
        SUM(COALESCE(bs."runs_scored",0))         AS runs_off_bat,    -- runs conceded (bat only)
        COUNT(*)                                  AS balls_bowled,    -- all deliveries
        SUM(                                      -- wickets credited to the bowler
            CASE
                WHEN wt."kind_out" IS NOT NULL
                 AND wt."kind_out" NOT IN ('run out',
                                           'retired hurt',
                                           'obstructing the field')
                THEN 1 ELSE 0
            END
        )                                         AS wickets
    FROM   "ball_by_ball"  AS bb
    LEFT JOIN "batsman_scored" AS bs
           ON  bb."match_id" = bs."match_id"
          AND bb."over_id"  = bs."over_id"
          AND bb."ball_id"  = bs."ball_id"
    LEFT JOIN "wicket_taken"  AS wt
           ON  bb."match_id" = wt."match_id"
          AND bb."over_id"  = wt."over_id"
          AND bb."ball_id"  = wt."ball_id"
    GROUP BY bb."match_id", bb."bowler"
),
bowler_totals AS (                -- cumulative figures for each bowler
    SELECT
        bowler_id,
        SUM(wickets)       AS total_wickets,
        SUM(runs_off_bat)  AS total_runs,
        SUM(balls_bowled)  AS total_balls
    FROM   delivery_stats
    GROUP BY bowler_id
),
best_performance AS (             -- best match figures per bowler (max wickets, min runs)
    SELECT
        bowler_id,
        wickets,
        runs_off_bat
    FROM (
        SELECT
            bowler_id,
            wickets,
            runs_off_bat,
            ROW_NUMBER() OVER (PARTITION BY bowler_id
                               ORDER BY wickets DESC, runs_off_bat ASC) AS rn
        FROM   delivery_stats
    )
    WHERE rn = 1
)
SELECT
    p."player_id",
    p."player_name",
    bt.total_wickets                                                    AS total_wickets,
    ROUND(bt.total_runs / (bt.total_balls/6.0), 4)                      AS economy_rate,
    ROUND(bt.total_balls / NULLIF(bt.total_wickets,0), 4)               AS strike_rate,
    best.wickets || '-' || best.runs_off_bat                            AS best_bowling
FROM   bowler_totals      AS bt
JOIN   "player"           AS p
       ON p."player_id" = bt.bowler_id
JOIN   best_performance   AS best
       ON best.bowler_id = bt.bowler_id
ORDER BY p."player_name";