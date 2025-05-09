SELECT p."player_name",
       ROUND((b_stats."total_runs_conceded" * 1.0) / w_stats."total_wickets", 4) AS "bowling_average"
FROM "player" AS p
JOIN (
    SELECT b."bowler",
           SUM(COALESCE(bs."runs_scored", 0) + COALESCE(e."extra_runs", 0)) AS "total_runs_conceded",
           COUNT(*) AS "deliveries_bowled"
    FROM "ball_by_ball" AS b
    LEFT JOIN "batsman_scored" AS bs
      ON b."match_id" = bs."match_id" AND
         b."over_id" = bs."over_id" AND
         b."ball_id" = bs."ball_id" AND
         b."innings_no" = bs."innings_no"
    LEFT JOIN "extra_runs" AS e
      ON b."match_id" = e."match_id" AND
         b."over_id" = e."over_id" AND
         b."ball_id" = e."ball_id" AND
         b."innings_no" = e."innings_no"
    WHERE b."bowler" IS NOT NULL
    GROUP BY b."bowler"
) AS b_stats ON p."player_id" = b_stats."bowler"
JOIN (
    SELECT b."bowler",
           COUNT(*) AS "total_wickets"
    FROM "ball_by_ball" AS b
    JOIN "wicket_taken" AS w
      ON b."match_id" = w."match_id" AND
         b."over_id" = w."over_id" AND
         b."ball_id" = w."ball_id" AND
         b."innings_no" = w."innings_no"
    WHERE w."kind_out" IN ('bowled', 'caught', 'lbw', 'stumped', 'hit wicket', 'caught and bowled')
    GROUP BY b."bowler"
) AS w_stats ON p."player_id" = w_stats."bowler"
WHERE w_stats."total_wickets" > 0
  AND b_stats."total_runs_conceded" > 0
  AND b_stats."deliveries_bowled" >= 6
ORDER BY "bowling_average" ASC
LIMIT 1;