WITH extras_per_ball AS (                            -- total extras on each ball
    SELECT  "match_id",
            "innings_no",
            "over_id",
            "ball_id",
            SUM("extra_runs")      AS extra_runs
    FROM    IPL.IPL.EXTRA_RUNS
    GROUP BY "match_id","innings_no","over_id","ball_id"
),  

ball_runs AS (                                      -- runs (batsman + extras) on each ball
    SELECT  bb."match_id",
            bb."innings_no",
            bb."over_id",
            bb."ball_id",
            bb."bowler",
            COALESCE(bs."runs_scored",0)
          + COALESCE(epb.extra_runs,0)  AS runs_in_ball
    FROM    IPL.IPL.BALL_BY_BALL    bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id" = bs."match_id"
           AND bb."innings_no" = bs."innings_no"
           AND bb."over_id"   = bs."over_id"
           AND bb."ball_id"   = bs."ball_id"
    LEFT JOIN extras_per_ball epb
           ON  bb."match_id" = epb."match_id"
           AND bb."innings_no" = epb."innings_no"
           AND bb."over_id"   = epb."over_id"
           AND bb."ball_id"   = epb."ball_id"
),

runs_per_over AS (                                  -- total runs conceded by a bowler in an over
    SELECT  "match_id",
            "innings_no",
            "over_id",
            "bowler",
            SUM(runs_in_ball)   AS runs_in_over
    FROM    ball_runs
    GROUP BY "match_id","innings_no","over_id","bowler"
),

max_over_per_match AS (                             -- maximum-run over in every match
    SELECT  "match_id",
            MAX(runs_in_over)  AS max_runs_in_match
    FROM    runs_per_over
    GROUP BY "match_id"
),

overs_match_max AS (                                -- the overs that reached that match maximum
    SELECT  r.*
    FROM    runs_per_over r
    JOIN    max_over_per_match m
           ON r."match_id" = m."match_id"
          AND r.runs_in_over = m.max_runs_in_match
),

bowler_best AS (                                    -- each bowler’s worst such over
    SELECT  "bowler",
            "match_id",
            runs_in_over,
            ROW_NUMBER() OVER (PARTITION BY "bowler"
                                ORDER BY runs_in_over DESC, "match_id") AS rn
    FROM    overs_match_max
),

top_bowlers AS (                                    -- pick top 3 bowlers overall
    SELECT  "bowler",
            "match_id",
            runs_in_over
    FROM    bowler_best
    WHERE   rn = 1
    ORDER BY runs_in_over DESC NULLS LAST
    LIMIT 3
)

SELECT  p."player_name"         AS bowler_name,
        t.runs_in_over, 
        t."match_id"
FROM    top_bowlers t
JOIN    IPL.IPL.PLAYER p
       ON t."bowler" = p."player_id"
ORDER BY t.runs_in_over DESC NULLS LAST;