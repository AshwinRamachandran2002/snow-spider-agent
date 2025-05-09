WITH BALL_TOTAL AS (          /* runs conceded on every ball */
    SELECT
        b."match_id",
        b."innings_no",
        b."over_id",
        b."ball_id",
        b."bowler",
        COALESCE(bs."runs_scored", 0) + COALESCE(er."extra_runs", 0) AS runs_on_ball
    FROM IPL.IPL."BALL_BY_BALL" b
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs
           ON  b."match_id"   = bs."match_id"
           AND b."innings_no" = bs."innings_no"
           AND b."over_id"    = bs."over_id"
           AND b."ball_id"    = bs."ball_id"
    LEFT JOIN IPL.IPL."EXTRA_RUNS" er
           ON  b."match_id"   = er."match_id"
           AND b."innings_no" = er."innings_no"
           AND b."over_id"    = er."over_id"
           AND b."ball_id"    = er."ball_id"
),
OVER_TOTAL AS (               /* runs conceded in every over by a bowler */
    SELECT
        "match_id",
        "innings_no",
        "over_id",
        "bowler",
        SUM(runs_on_ball) AS runs_conceded
    FROM BALL_TOTAL
    GROUP BY
        "match_id",
        "innings_no",
        "over_id",
        "bowler"
),
MATCH_MAX_OVERS AS (          /* overs that were the most expensive in each match */
    SELECT
        ot.*,
        MAX(runs_conceded) OVER (PARTITION BY "match_id") AS max_runs_in_match
    FROM OVER_TOTAL ot
    QUALIFY runs_conceded = max_runs_in_match
),
BOWLER_BEST AS (              /* each bowler’s single worst of those overs */
    SELECT
        "bowler",
        runs_conceded,
        "match_id",
        ROW_NUMBER() OVER (PARTITION BY "bowler"
                           ORDER BY runs_conceded DESC, "match_id") AS rn
    FROM MATCH_MAX_OVERS
),
TOP_BOWLERS AS (              /* three worst figures overall */
    SELECT
        "bowler",
        runs_conceded,
        "match_id"
    FROM BOWLER_BEST
    WHERE rn = 1
    ORDER BY runs_conceded DESC NULLS LAST
    LIMIT 3
)
SELECT
    p."player_name" AS bowler_name,
    t."match_id",
    t.runs_conceded
FROM TOP_BOWLERS t
JOIN IPL.IPL."PLAYER" p
      ON p."player_id" = t."bowler"
ORDER BY t.runs_conceded DESC NULLS LAST;