WITH
/* 1) Runs off the bat per over */
batsman_per_over AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM("runs_scored") AS runs
    FROM "batsman_scored"
    GROUP BY "match_id", "innings_no", "over_id"
),
/* 2) Extra runs (wides, no‑balls, leg‑byes, …) per over */
extra_per_over AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM("extra_runs") AS runs
    FROM "extra_runs"
    GROUP BY "match_id", "innings_no", "over_id"
),
/* 3) Combine both kinds of runs and total them for every over */
over_totals AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM(runs) AS total_runs
    FROM (
        SELECT * FROM batsman_per_over
        UNION ALL
        SELECT * FROM extra_per_over
    )
    GROUP BY "match_id", "innings_no", "over_id"
),
/* 4) Rank overs inside every match by the runs conceded
      (ties broken by lower innings/over numbers) and attach the bowler */
ranked_overs AS (
    SELECT  o."match_id",
            o."innings_no",
            o."over_id",
            o."total_runs",
            ( SELECT "bowler"
              FROM "ball_by_ball" bb
              WHERE bb."match_id"   = o."match_id"
                AND bb."innings_no" = o."innings_no"
                AND bb."over_id"    = o."over_id"
              LIMIT 1
            ) AS bowler_id,
            ROW_NUMBER() OVER (
                PARTITION BY o."match_id"
                ORDER BY o."total_runs" DESC,
                         o."innings_no",
                         o."over_id"
            ) AS rn
    FROM over_totals o
),
/* 5) Keep only the single highest‑run over for every match */
best_over_per_match AS (
    SELECT *
    FROM ranked_overs
    WHERE rn = 1
)
/* 6) Average of those highest‑run overs across all matches */
SELECT AVG(total_runs) AS average_highest_over_runs
FROM   best_over_per_match;