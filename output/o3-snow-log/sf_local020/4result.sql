WITH ball_runs AS (
    SELECT
        bb."bowler",
        COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0) AS "runs_conceded"
    FROM IPL.IPL.BALL_BY_BALL bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON bb."match_id"   = bs."match_id"
          AND bb."innings_no" = bs."innings_no"
          AND bb."over_id"    = bs."over_id"
          AND bb."ball_id"    = bs."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS er
           ON bb."match_id"   = er."match_id"
          AND bb."innings_no" = er."innings_no"
          AND bb."over_id"    = er."over_id"
          AND bb."ball_id"    = er."ball_id"
), 
runs_per_bowler AS (
    SELECT
        "bowler",
        SUM("runs_conceded") AS "total_runs"
    FROM ball_runs
    GROUP BY "bowler"
), 
wickets_per_bowler AS (
    SELECT
        bb."bowler",
        COUNT(*) AS "wickets"
    FROM IPL.IPL.WICKET_TAKEN wt
    JOIN IPL.IPL.BALL_BY_BALL bb
          ON bb."match_id"   = wt."match_id"
         AND bb."innings_no" = wt."innings_no"
         AND bb."over_id"    = wt."over_id"
         AND bb."ball_id"    = wt."ball_id"
    WHERE LOWER(wt."kind_out") <> 'run out'      -- exclude run-outs (not credited to bowler)
    GROUP BY bb."bowler"
), 
bowling_avg AS (
    SELECT
        r."bowler",
        r."total_runs",
        w."wickets",
        r."total_runs" / w."wickets" AS "avg_per_wicket"
    FROM runs_per_bowler r
    JOIN wickets_per_bowler w
          ON r."bowler" = w."bowler"
    WHERE w."wickets" > 0
)
SELECT
    p."player_name",
    ROUND(b."avg_per_wicket", 4) AS "bowling_average"
FROM bowling_avg b
JOIN IPL.IPL.PLAYER p
      ON p."player_id" = b."bowler"
ORDER BY b."avg_per_wicket" ASC NULLS LAST
LIMIT 1;