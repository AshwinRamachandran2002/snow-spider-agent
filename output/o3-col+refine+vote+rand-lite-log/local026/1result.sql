WITH over_runs AS (
    -- Runs conceded by each bowler in every over of every match
    SELECT
        bb."match_id",
        bb."bowler",
        bb."over_id",
        SUM(
            COALESCE(bs."runs_scored", 0) +
            COALESCE(er."extra_runs", 0)
        ) AS runs_in_over
    FROM "ball_by_ball" AS bb
    LEFT JOIN "batsman_scored" AS bs
           ON  bs."match_id"   = bb."match_id"
           AND bs."over_id"    = bb."over_id"
           AND bs."ball_id"    = bb."ball_id"
           AND bs."innings_no" = bb."innings_no"
    LEFT JOIN "extra_runs" AS er
           ON  er."match_id"   = bb."match_id"
           AND er."over_id"    = bb."over_id"
           AND er."ball_id"    = bb."ball_id"
           AND er."innings_no" = bb."innings_no"
    GROUP BY bb."match_id", bb."bowler", bb."over_id"
),
match_max AS (
    -- Maximum runs conceded in a single over for each match
    SELECT
        "match_id",
        MAX(runs_in_over) AS max_runs_in_match
    FROM over_runs
    GROUP BY "match_id"
),
filtered AS (
    -- Keep only those overs that are the costliest in their match
    SELECT o.*
    FROM   over_runs o
    JOIN   match_max m
           ON m."match_id"         = o."match_id"
          AND m.max_runs_in_match  = o.runs_in_over
)
-- Top-3 bowlers (and matches) that conceded the highest runs
SELECT
    f."bowler"                     AS bowler_id,
    p."player_name",
    f."match_id",
    f.runs_in_over                AS runs_conceded_in_that_over
FROM   filtered f
JOIN   "player" p
       ON p."player_id" = f."bowler"
ORDER  BY f.runs_in_over DESC
LIMIT 3;