/* 1.  Runs scored by batsmen per over */
WITH bat_runs AS (
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM("runs_scored")                    AS "bat_runs"
    FROM   "batsman_scored"
    GROUP  BY "match_id","innings_no","over_id"
),

/* 2.  Extra runs per over  */
extra_runs_cte AS (                             -- renamed to avoid clash with table name
    SELECT "match_id",
           "innings_no",
           "over_id",
           SUM("extra_runs")                    AS "extra_runs"
    FROM   "extra_runs"
    GROUP  BY "match_id","innings_no","over_id"
),

/* 3.  Total runs in each over (batting + extras) */
over_totals AS (
    SELECT b."match_id",
           b."innings_no",
           b."over_id",
           b."bat_runs" + COALESCE(e."extra_runs",0) AS "total_runs"
    FROM   bat_runs b
    LEFT JOIN extra_runs_cte e
           ON  e."match_id"   = b."match_id"
           AND e."innings_no" = b."innings_no"
           AND e."over_id"    = b."over_id"
),

/* 4.  Highest-scoring over(s) for every match */
max_over AS (
    SELECT ot.*
    FROM   over_totals ot
    WHERE  ot."total_runs" = (
              SELECT MAX(ot2."total_runs")
              FROM   over_totals ot2
              WHERE  ot2."match_id" = ot."match_id"
          )
),

/* 5.  Bowler who delivered that over (choose smallest id if multiple) */
bowler_for_max AS (
    SELECT mo."match_id",
           mo."total_runs",
           MIN(bb."bowler")                     AS "bowler_id"
    FROM   max_over mo
    JOIN   "ball_by_ball" bb
           ON  bb."match_id"   = mo."match_id"
           AND bb."innings_no" = mo."innings_no"
           AND bb."over_id"    = mo."over_id"
    GROUP  BY mo."match_id"
),

/* 6.  Attach bowler name (for completeness) */
match_best_over AS (
    SELECT bf."match_id",
           p."player_name"                      AS "bowler_name",
           bf."total_runs"
    FROM   bowler_for_max bf
    JOIN   "player" p
           ON p."player_id" = bf."bowler_id"
)

/* 7.  Average runs of the highest-scoring over across all matches */
SELECT AVG("total_runs") AS "avg_best_over_runs"
FROM   match_best_over;