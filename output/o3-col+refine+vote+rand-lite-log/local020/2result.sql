WITH wickets AS (
    SELECT b."bowler",
           COUNT(*) AS wkts
    FROM "wicket_taken" w
    JOIN "ball_by_ball" b
      ON w."match_id" = b."match_id"
     AND w."over_id"  = b."over_id"
     AND w."ball_id"  = b."ball_id"
    GROUP BY b."bowler"
),
runs AS (
    SELECT b."bowler",
           SUM(COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0)) AS runs_conceded
    FROM "ball_by_ball" b
    LEFT JOIN "batsman_scored" bs
           ON b."match_id" = bs."match_id"
          AND b."over_id"  = bs."over_id"
          AND b."ball_id"  = bs."ball_id"
    LEFT JOIN "extra_runs" er
           ON b."match_id" = er."match_id"
          AND b."over_id"  = er."over_id"
          AND b."ball_id"  = er."ball_id"
    GROUP BY b."bowler"
)
SELECT p."player_name"                      AS bowler,
       ROUND(1.0 * r."runs_conceded" / w."wkts", 4) AS bowling_average
FROM runs     r
JOIN wickets  w  ON r."bowler" = w."bowler"
JOIN "player" p ON p."player_id" = r."bowler"
WHERE w."wkts" > 0
ORDER BY 1.0 * r."runs_conceded" / w."wkts" ASC
LIMIT 1;