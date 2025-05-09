WITH ball_runs AS (                         -- runs conceded on every ball
    SELECT
        b."match_id",
        b."innings_no",
        b."over_id",
        b."ball_id",
        b."bowler",
        COALESCE(bs."runs_scored", 0) + COALESCE(er."extra_runs", 0) AS ball_runs
    FROM IPL.IPL.BALL_BY_BALL b
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  b."match_id"   = bs."match_id"
           AND b."innings_no" = bs."innings_no"
           AND b."over_id"    = bs."over_id"
           AND b."ball_id"    = bs."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS er
           ON  b."match_id"   = er."match_id"
           AND b."innings_no" = er."innings_no"
           AND b."over_id"    = er."over_id"
           AND b."ball_id"    = er."ball_id"
),

/* total runs conceded in every over (innings kept separate) */
over_totals AS (
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        SUM(ball_runs) AS over_runs
    FROM ball_runs
    GROUP BY "match_id", "innings_no", "over_id"
),

/* the over(s) that conceded the maximum runs in each match */
max_overs AS (
    SELECT ot.*
    FROM over_totals ot
    JOIN (
        SELECT
            "match_id",
            MAX(over_runs) AS max_over_runs
        FROM over_totals
        GROUP BY "match_id"
    ) mx
      ON ot."match_id"  = mx."match_id"
     AND ot.over_runs   = mx.max_over_runs
),

/* runs conceded by every bowler in those maximum-run overs */
over_bowler_runs AS (
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        "bowler",
        SUM(ball_runs) AS runs_conceded
    FROM ball_runs
    GROUP BY "match_id", "innings_no", "over_id", "bowler"
),

bowler_in_max_overs AS (
    SELECT
        obr."bowler",
        obr."match_id",
        obr.runs_conceded
    FROM over_bowler_runs obr
    JOIN max_overs mo
      ON  obr."match_id"   = mo."match_id"
      AND obr."innings_no" = mo."innings_no"
      AND obr."over_id"    = mo."over_id"
),

/* keep the single worst (highest-runs) over for every bowler */
bowler_max_run AS (
    SELECT
        "bowler",
        "match_id",
        runs_conceded,
        ROW_NUMBER() OVER (PARTITION BY "bowler"
                           ORDER BY runs_conceded DESC, "match_id") AS rn
    FROM bowler_in_max_overs
),

/* top-3 bowlers by runs conceded in a single (max-run) over */
top_bowlers AS (
    SELECT
        "bowler",
        "match_id",
        runs_conceded
    FROM bowler_max_run
    WHERE rn = 1
    ORDER BY runs_conceded DESC NULLS LAST
    LIMIT 3
)

SELECT
    p."player_name" AS bowler_name,
    tb."match_id",
    tb.runs_conceded
FROM top_bowlers tb
JOIN IPL.IPL.PLAYER p
  ON tb."bowler" = p."player_id"
ORDER BY tb.runs_conceded DESC NULLS LAST;