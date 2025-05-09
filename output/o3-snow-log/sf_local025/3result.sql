/*  Step-by-step
    1. Aggregate batsman + extra runs for every (match, innings, over)
    2. Per match, keep the single highest-scoring over
    3. Fetch the bowler who delivered that over
    4. Add bowler name
    5. Compute the average runs of these peak overs across all matches          */

WITH over_runs AS (               -- runs scored in every over
    SELECT  bs."match_id",
            bs."innings_no",
            bs."over_id",
            /* batsman runs + extras (extras may be NULL) */
            SUM(bs."runs_scored") + COALESCE(SUM(er."extra_runs"),0)    AS "total_runs_over"
    FROM    IPL.IPL.BATSMAN_SCORED  bs
    LEFT JOIN IPL.IPL.EXTRA_RUNS    er
           ON  bs."match_id"   = er."match_id"
           AND bs."innings_no" = er."innings_no"
           AND bs."over_id"    = er."over_id"
           AND bs."ball_id"    = er."ball_id"
    GROUP BY bs."match_id",
             bs."innings_no",
             bs."over_id"
),
per_match_best AS (               -- rank overs inside every match
    SELECT  "match_id",
            "innings_no",
            "over_id",
            "total_runs_over",
            RANK() OVER (PARTITION BY "match_id"
                          ORDER BY "total_runs_over" DESC)              AS "rnk"
    FROM    over_runs
),
best_over AS (                    -- one over (the top ranked) per match
    SELECT  "match_id",
            "innings_no",
            "over_id",
            "total_runs_over"
    FROM    per_match_best
    WHERE   "rnk" = 1
),
best_over_bowler AS (             -- attach bowler for that over
    SELECT  bo."match_id",
            bo."innings_no",
            bo."over_id",
            bo."total_runs_over",
            MIN(bbb."bowler")                                         AS "bowler_id"   -- same for all balls
    FROM    best_over                   bo
    JOIN    IPL.IPL.BALL_BY_BALL        bbb
           ON  bo."match_id"   = bbb."match_id"
           AND bo."innings_no" = bbb."innings_no"
           AND bo."over_id"    = bbb."over_id"
    GROUP BY bo."match_id",
             bo."innings_no",
             bo."over_id",
             bo."total_runs_over"
),
final AS (                        -- add bowler name
    SELECT  bob."match_id",
            bob."innings_no",
            bob."over_id",
            bob."total_runs_over",
            bob."bowler_id",
            p."player_name"                                           AS "bowler_name"
    FROM    best_over_bowler      bob
    LEFT JOIN IPL.IPL.PLAYER      p
           ON  bob."bowler_id" = p."player_id"
)
SELECT  "match_id",
        "innings_no",
        "over_id",
        "total_runs_over",
        "bowler_id",
        "bowler_name",
        /* average of all highest-scoring overs across matches */
        AVG("total_runs_over") OVER ()                                 AS "avg_of_highest_over_runs"
FROM    final
ORDER BY "match_id";