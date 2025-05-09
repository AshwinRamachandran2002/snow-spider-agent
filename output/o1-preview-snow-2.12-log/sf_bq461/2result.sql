SELECT
  "period",
  "game_clock",
  CONCAT(
    TO_CHAR(
      ROUND(
        SUM(CASE WHEN "team_id" = '2267a1f4-68f6-418b-aaf6-2aa0c4b291f1' THEN "points_scored" ELSE 0 END)
        OVER (ORDER BY "period", "elapsed_time_sec"), 4
      ),
      'FM9999999.0000'
    ),
    '-',
    TO_CHAR(
      ROUND(
        SUM(CASE WHEN "team_id" = '80962f09-8821-48b6-8cf0-0cf0eea56aa8' THEN "points_scored" ELSE 0 END)
        OVER (ORDER BY "period", "elapsed_time_sec"), 4
      ),
      'FM9999999.0000'
    )
  ) AS "Team Scores",
  "team_market" AS "Scoring Team",
  "event_description"
FROM
  NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
WHERE
  "game_id" = '95cda731-b593-42cd-8573-621a3d1369dc' AND
  "points_scored" > 0
ORDER BY
  "period" ASC,
  "elapsed_time_sec" ASC;