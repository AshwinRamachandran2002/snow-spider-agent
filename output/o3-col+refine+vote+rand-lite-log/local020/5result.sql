WITH runs AS (
    SELECT b."bowler",
           SUM( COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0) ) AS runs_conceded
    FROM "ball_by_ball" AS b
    LEFT JOIN "batsman_scored" AS bs
           ON  b."match_id"   = bs."match_id"
          AND b."over_id"    = bs."over_id"
          AND b."ball_id"    = bs."ball_id"
          AND b."innings_no" = bs."innings_no"
    LEFT JOIN "extra_runs" AS er
           ON  b."match_id"   = er."match_id"
          AND b."over_id"    = er."over_id"
          AND b."ball_id"    = er."ball_id"
          AND b."innings_no" = er."innings_no"
    GROUP BY b."bowler"
),
wickets AS (
    SELECT b."bowler",
           COUNT(*) AS wickets_taken
    FROM "ball_by_ball" AS b
    JOIN "wicket_taken" AS w
           ON  b."match_id"   = w."match_id"
          AND b."over_id"    = w."over_id"
          AND b."ball_id"    = w."ball_id"
          AND b."innings_no" = w."innings_no"
    GROUP BY b."bowler"
),
averages AS (
    SELECT r."bowler",
           r."runs_conceded",
           w."wickets_taken",
           1.0 * r."runs_conceded" / w."wickets_taken" AS bowling_average
    FROM runs    AS r
    JOIN wickets AS w
      ON r."bowler" = w."bowler"
    WHERE w."wickets_taken" > 0
)
SELECT p."player_name"                           AS bowler_name,
       ROUND(a."bowling_average", 4)             AS bowling_average
FROM averages AS a
JOIN "player" AS p
  ON a."bowler" = p."player_id"
ORDER BY a."bowling_average" ASC
LIMIT 1;