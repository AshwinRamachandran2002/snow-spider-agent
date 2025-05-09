WITH runs_conceded AS (
    SELECT 
        b."bowler",
        SUM( COALESCE(s."runs_scored",0) + COALESCE(e."extra_runs",0) ) AS runs
    FROM "ball_by_ball" AS b
    LEFT JOIN "batsman_scored" AS s
           ON b."match_id" = s."match_id"
          AND b."over_id"  = s."over_id"
          AND b."ball_id"  = s."ball_id"
          AND b."innings_no" = s."innings_no"
    LEFT JOIN "extra_runs"   AS e
           ON b."match_id" = e."match_id"
          AND b."over_id"  = e."over_id"
          AND b."ball_id"  = e."ball_id"
          AND b."innings_no" = e."innings_no"
    GROUP BY b."bowler"
),
wickets_taken AS (
    SELECT 
        b."bowler",
        COUNT(*) AS wickets
    FROM "ball_by_ball" AS b
    JOIN "wicket_taken" AS w
      ON b."match_id" = w."match_id"
     AND b."over_id"  = w."over_id"
     AND b."ball_id"  = w."ball_id"
     AND b."innings_no" = w."innings_no"
    GROUP BY b."bowler"
),
bowling_average AS (
    SELECT 
        r."bowler",
        CAST(r.runs AS FLOAT) / w.wickets AS avg_per_wicket
    FROM runs_conceded r
    JOIN wickets_taken w
      ON r."bowler" = w."bowler"
    WHERE w.wickets > 0
)
SELECT 
    p."player_name"   AS bowler_name,
    b.avg_per_wicket  AS bowling_average
FROM bowling_average b
JOIN "player" p
  ON p."player_id" = b."bowler"
ORDER BY b.avg_per_wicket ASC
LIMIT 1;