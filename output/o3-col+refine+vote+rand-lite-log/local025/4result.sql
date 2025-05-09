WITH ball_runs AS (           -- 1.  total runs for every delivery
    SELECT  bb."match_id",
            bb."innings_no",
            bb."over_id",
            bb."ball_id",
            COALESCE(bs."runs_scored",0) +
            COALESCE(er."extra_runs",0)          AS runs_this_ball,
            bb."bowler"
    FROM   "ball_by_ball"      AS bb
    LEFT  JOIN "batsman_scored" AS bs
           ON  bb."match_id"   = bs."match_id"
          AND bb."over_id"    = bs."over_id"
          AND bb."ball_id"    = bs."ball_id"
          AND bb."innings_no" = bs."innings_no"
    LEFT  JOIN "extra_runs"     AS er
           ON  bb."match_id"   = er."match_id"
          AND bb."over_id"    = er."over_id"
          AND bb."ball_id"    = er."ball_id"
          AND bb."innings_no" = er."innings_no"
),
over_totals AS (              -- 2.  sum the runs for every over (per innings)
    SELECT  "match_id",
            "innings_no",
            "over_id",
            SUM(runs_this_ball) AS runs_in_over
    FROM    ball_runs
    GROUP BY "match_id","innings_no","over_id"
),
best_over_per_match AS (      -- 3.  the single highest-scoring over in each match
    SELECT  ot."match_id",
            ot."innings_no",
            ot."over_id",
            ot.runs_in_over
    FROM   over_totals AS ot
    JOIN  ( SELECT  "match_id",
                    MAX(runs_in_over) AS max_runs
            FROM    over_totals
            GROUP BY "match_id"
          ) mx
      ON  ot."match_id"   = mx."match_id"
     AND ot.runs_in_over  = mx.max_runs
),
best_over_bowler AS (         -- 4.  attach bowler for those overs
    SELECT DISTINCT
           bo."match_id",
           bo."innings_no",
           bo."over_id",
           bo.runs_in_over,
           bb."bowler"
    FROM   best_over_per_match AS bo
    JOIN   "ball_by_ball"      AS bb
      ON  bo."match_id"   = bb."match_id"
     AND bo."innings_no" = bb."innings_no"
     AND bo."over_id"    = bb."over_id"
),
best_over_with_name AS (      -- 5.  get bowler name
    SELECT  bob."match_id",
            bob."innings_no",
            bob."over_id",
            bob.runs_in_over,
            p."player_name" AS bowler_name
    FROM    best_over_bowler AS bob
    LEFT   JOIN "player"     AS p
           ON bob."bowler" = p."player_id"
),
average_calc AS (             -- 6.  average of all match-level peak overs
    SELECT  AVG(runs_in_over) AS average_highest_over_runs
    FROM    best_over_with_name
)
-- 7.  final output: details for every match plus the overall average
SELECT  b."match_id",
        b."innings_no",
        b."over_id",
        b.bowler_name,
        b.runs_in_over              AS highest_over_runs_in_match,
        a.average_highest_over_runs
FROM    best_over_with_name  AS b,
        average_calc         AS a;