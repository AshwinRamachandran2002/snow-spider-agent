WITH "over_totals" AS (
    SELECT
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        bb."bowler",
        SUM(COALESCE(bs."runs_scored", 0) + COALESCE(er."extra_runs", 0)) AS "total_runs"
    FROM
        "ball_by_ball" bb
    LEFT JOIN "batsman_scored" bs ON bb."match_id" = bs."match_id"
        AND bb."innings_no" = bs."innings_no"
        AND bb."over_id" = bs."over_id"
        AND bb."ball_id" = bs."ball_id"
    LEFT JOIN "extra_runs" er ON bb."match_id" = er."match_id"
        AND bb."innings_no" = er."innings_no"
        AND bb."over_id" = er."over_id"
        AND bb."ball_id" = er."ball_id"
    GROUP BY
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        bb."bowler"
),
"max_over_totals" AS (
    SELECT
        ot."match_id",
        ot."innings_no",
        MAX(ot."total_runs") AS "max_total_runs"
    FROM
        "over_totals" ot
    GROUP BY
        ot."match_id",
        ot."innings_no"
),
"highest_over_per_innings" AS (
    SELECT
        ot."match_id",
        ot."innings_no",
        MIN(ot."over_id") AS "over_id",
        ot."bowler",
        ot."total_runs"
    FROM
        "over_totals" ot
    INNER JOIN "max_over_totals" mot ON ot."match_id" = mot."match_id"
        AND ot."innings_no" = mot."innings_no"
        AND ot."total_runs" = mot."max_total_runs"
    GROUP BY
        ot."match_id",
        ot."innings_no"
)
SELECT
    ROUND(AVG("total_runs"), 4) AS "average_highest_over_total"
FROM
    "highest_over_per_innings";