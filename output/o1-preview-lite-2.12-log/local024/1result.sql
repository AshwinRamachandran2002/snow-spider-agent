SELECT
  per_player.country_name,
  ROUND((SUM(per_player.total_runs) * 1.0) / NULLIF(SUM(per_player.matches_played), 0), 4) AS Average_Runs_per_Match,
  ROUND((SUM(per_player.total_runs) * 1.0) / NULLIF(SUM(per_player.dismissal_count), 0), 4) AS Batting_Average
FROM (
  SELECT
    p."country_name",
    COALESCE(r."total_runs", 0) AS "total_runs",
    COALESCE(m."matches_played", 0) AS "matches_played",
    COALESCE(w."dismissal_count", 0) AS "dismissal_count"
  FROM "player" AS p
  LEFT JOIN (
    SELECT b."striker", SUM(s."runs_scored") AS "total_runs"
    FROM "ball_by_ball" AS b
    JOIN "batsman_scored" AS s
      ON b."match_id" = s."match_id"
      AND b."over_id" = s."over_id"
      AND b."ball_id" = s."ball_id"
      AND b."innings_no" = s."innings_no"
    GROUP BY b."striker"
  ) AS r ON p."player_id" = r."striker"
  LEFT JOIN (
    SELECT "player_id", COUNT(DISTINCT "match_id") AS "matches_played"
    FROM "player_match"
    GROUP BY "player_id"
  ) AS m ON p."player_id" = m."player_id"
  LEFT JOIN (
    SELECT "player_out", COUNT(*) AS "dismissal_count"
    FROM "wicket_taken"
    GROUP BY "player_out"
  ) AS w ON p."player_id" = w."player_out"
) AS per_player
GROUP BY per_player.country_name
ORDER BY Average_Runs_per_Match DESC
LIMIT 5;