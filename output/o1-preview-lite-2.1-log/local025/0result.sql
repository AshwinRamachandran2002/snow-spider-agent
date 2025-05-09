SELECT ROUND(AVG(max_runs), 4) AS "average_highest_runs_conceded_per_over"
FROM (
    SELECT "match_id", MAX("total_runs") AS max_runs
    FROM (
        SELECT
            bb."match_id",
            bb."over_id",
            SUM(COALESCE(bs."runs_scored", 0) + COALESCE(er."extra_runs", 0)) AS "total_runs"
        FROM "ball_by_ball" AS bb
        LEFT JOIN "batsman_scored" AS bs
          ON bb."match_id" = bs."match_id"
          AND bb."over_id" = bs."over_id"
          AND bb."ball_id" = bs."ball_id"
          AND bb."innings_no" = bs."innings_no"
        LEFT JOIN "extra_runs" AS er
          ON bb."match_id" = er."match_id"
          AND bb."over_id" = er."over_id"
          AND bb."ball_id" = er."ball_id"
          AND bb."innings_no" = er."innings_no"
        GROUP BY bb."match_id", bb."over_id"
    ) AS over_totals
    GROUP BY "match_id"
) AS max_over_totals;