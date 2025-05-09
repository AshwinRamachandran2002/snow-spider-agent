SELECT
  "period",
  "game_clock",
  "team_name" AS "scoring_team",
  "points_scored",
  SUM(CASE WHEN "team_name" = 'Wildcats' THEN "points_scored" ELSE 0 END) OVER (
    ORDER BY "period", "elapsed_time_sec"
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS "wildcats_score",
  SUM(CASE WHEN "team_name" = 'Fighting Irish' THEN "points_scored" ELSE 0 END) OVER (
    ORDER BY "period", "elapsed_time_sec"
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS "fighting_irish_score",
  "event_description"
FROM
  NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
WHERE
  "game_id" = '95cda731-b593-42cd-8573-621a3d1369dc' AND
  "points_scored" > 0
ORDER BY
  "period",
  "elapsed_time_sec";