WITH combined_runs AS (                      -- all runs (batsman + extras) ball-wise
    SELECT "match_id","innings_no","over_id","runs_scored" AS runs
    FROM   "batsman_scored"
    UNION ALL
    SELECT "match_id","innings_no","over_id","extra_runs"  AS runs
    FROM   "extra_runs"
),
over_runs AS (                               -- runs per over
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM(runs)           AS over_total
    FROM   combined_runs
    GROUP  BY "match_id","innings_no","over_id"
),
ranked AS (                                  -- one (highest) over per match
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY "match_id"
                              ORDER BY over_total DESC,
                                       "innings_no",
                                       "over_id") AS rn
    FROM   over_runs
),
best_over AS (                               -- keep only the single highest over
    SELECT "match_id","innings_no","over_id","over_total"
    FROM   ranked
    WHERE  rn = 1
),
bowler_for_over AS (                         -- bowler who delivered that over
    SELECT b."match_id",
           b."innings_no",
           b."over_id",
           MIN(b."bowler") AS bowler_id      -- MIN() = one bowler if any oddities
    FROM   "ball_by_ball" b
    JOIN   best_over bo
           ON  bo."match_id" = b."match_id"
           AND bo."innings_no"=b."innings_no"
           AND bo."over_id"   =b."over_id"
    GROUP  BY b."match_id",b."innings_no",b."over_id"
),
best_over_detail AS (                        -- add bowler name
    SELECT bo."match_id",
           bo."innings_no",
           bo."over_id",
           bo."over_total",
           p."player_name"  AS bowler_name
    FROM   best_over        bo
    JOIN   bowler_for_over  bf
           ON bf."match_id" = bo."match_id"
          AND bf."innings_no"=bo."innings_no"
          AND bf."over_id"   =bo."over_id"
    JOIN   "player"         p
           ON p."player_id" = bf."bowler_id"
)
SELECT  bod."match_id",
        bod."innings_no",
        bod."over_id",
        bod."over_total",
        bod."bowler_name",
        AVG(bod."over_total") OVER () AS avg_highest_over_runs   -- average across matches
FROM    best_over_detail bod
ORDER BY bod."match_id";