WITH wicket_counts AS (
    SELECT bb."bowler",
           COUNT(*) AS "wickets"
    FROM "wicket_taken" wt
    JOIN "ball_by_ball" bb
      USING ("match_id", "over_id", "ball_id", "innings_no")
    GROUP BY bb."bowler"
),
bat_runs AS (
    SELECT bb."bowler",
           SUM(bs."runs_scored") AS "bat_runs"
    FROM "ball_by_ball" bb
    JOIN "batsman_scored" bs
      USING ("match_id", "over_id", "ball_id", "innings_no")
    GROUP BY bb."bowler"
),
extra_runs_cte AS (          -- renamed to avoid clash with table name
    SELECT bb."bowler",
           SUM(er."extra_runs") AS "extra_runs"
    FROM "ball_by_ball" bb
    JOIN "extra_runs" er
      USING ("match_id", "over_id", "ball_id", "innings_no")
    GROUP BY bb."bowler"
),
run_counts AS (
    SELECT br."bowler",
           br."bat_runs" + COALESCE(er."extra_runs", 0) AS "runs"
    FROM bat_runs br
    LEFT JOIN extra_runs_cte er
           ON br."bowler" = er."bowler"
),
bowling_avg AS (
    SELECT wc."bowler",
           1.0 * rc."runs" / wc."wickets" AS "bowling_average"
    FROM wicket_counts wc
    JOIN run_counts  rc ON rc."bowler" = wc."bowler"
    WHERE wc."wickets" > 0
)
SELECT p."player_name",
       ROUND(ba."bowling_average", 2) AS "bowling_average"
FROM bowling_avg ba
JOIN "player" p ON p."player_id" = ba."bowler"
ORDER BY ba."bowling_average" ASC
LIMIT 1;