WITH per_ball AS (   -- 1️⃣ every delivery with runs-off-the-bat and “credited” wicket flag
    SELECT
        bb."bowler",
        bb."match_id",
        COALESCE(bs."runs_scored", 0)                                   AS runs_off_bat,
        CASE
            WHEN wt."match_id" IS NOT NULL
                 AND LOWER(wt."kind_out") NOT IN
                     ('run out', 'retired hurt', 'obstructing the field')
            THEN 1 ELSE 0
        END                                                             AS wicket_flag
    FROM IPL.IPL."BALL_BY_BALL"  bb
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs
           ON bb."match_id" = bs."match_id"
          AND bb."over_id"  = bs."over_id"
          AND bb."ball_id"  = bs."ball_id"
    LEFT JOIN IPL.IPL."WICKET_TAKEN" wt
           ON wt."match_id" = bb."match_id"
          AND wt."over_id"  = bb."over_id"
          AND wt."ball_id"  = bb."ball_id"
),

overall AS (           -- 2️⃣ career-level figures for every bowler
    SELECT
        "bowler"                                AS bowler_id,
        COUNT(*)                                AS balls_bowled,
        SUM(runs_off_bat)                       AS runs_conceded,
        SUM(wicket_flag)                        AS total_wickets
    FROM  per_ball
    GROUP BY "bowler"
),

per_match AS (         -- 3️⃣ figures per bowler per match (for “best bowling”)
    SELECT
        "bowler"        AS bowler_id,
        "match_id",
        SUM(wicket_flag)                    AS wickets_in_match,
        SUM(runs_off_bat)                   AS runs_conceded
    FROM  per_ball
    GROUP BY "bowler", "match_id"
),

best_performance AS (  -- 4️⃣ pick the match with most wickets, then fewest runs
    SELECT
        bowler_id,
        CONCAT(wickets_in_match, '-', runs_conceded) AS best_bowling
    FROM (
        SELECT
            pm.*,
            ROW_NUMBER() OVER (PARTITION BY bowler_id
                               ORDER BY wickets_in_match DESC,
                                        runs_conceded     ASC) AS rn
        FROM per_match pm
    )
    WHERE rn = 1
)

SELECT
    p."player_name",
    o.total_wickets,
    ROUND(o.runs_conceded * 6.0 / NULLIF(o.balls_bowled, 0), 4)  AS economy_rate,
    ROUND(o.balls_bowled  * 1.0 / NULLIF(o.total_wickets, 0), 4) AS strike_rate,
    bp.best_bowling
FROM  overall           o
JOIN  best_performance  bp ON bp.bowler_id = o.bowler_id
LEFT  JOIN IPL.IPL."PLAYER" p ON p."player_id" = o.bowler_id
ORDER BY o.total_wickets DESC NULLS LAST;