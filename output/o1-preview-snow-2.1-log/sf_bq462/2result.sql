(
SELECT
  'Largest Venues' AS "Category",
  'N/A' AS "Date",
  "venue_name" AS "Matchup or Venue",
  TO_CHAR(ROUND("venue_capacity", 4), 'FM9999999.0000') AS "Key Metric"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_TEAMS
WHERE "venue_capacity" IS NOT NULL
ORDER BY CAST("venue_capacity" AS INTEGER) DESC NULLS LAST
LIMIT 5
)
UNION ALL
(
SELECT
  'Biggest Championship Margins' AS "Category",
  TO_CHAR("game_date", 'YYYY-MM-DD') AS "Date",
  "win_name" || ' vs ' || "lose_name" AS "Matchup or Venue",
  TO_CHAR(ROUND("win_pts" - "lose_pts", 4), 'FM9999999.0000') AS "Key Metric"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES
WHERE "season" >= 2015 AND "round" = 6 AND "win_pts" IS NOT NULL AND "lose_pts" IS NOT NULL
ORDER BY ("win_pts" - "lose_pts") DESC NULLS LAST
LIMIT 5
)
UNION ALL
(
SELECT
  'Highest Scoring Games' AS "Category",
  TO_CHAR("scheduled_date", 'YYYY-MM-DD') AS "Date",
  "h_name" || ' vs ' || "a_name" AS "Matchup or Venue",
  TO_CHAR(ROUND("h_points_game" + "a_points_game", 4), 'FM9999999.0000') AS "Key Metric"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
WHERE "scheduled_date" >= '2010-01-01' AND "h_points_game" IS NOT NULL AND "a_points_game" IS NOT NULL
ORDER BY ("h_points_game" + "a_points_game") DESC NULLS LAST
LIMIT 5
)
UNION ALL
(
SELECT
  'Most Three-Pointers in a Matchup' AS "Category",
  TO_CHAR("scheduled_date", 'YYYY-MM-DD') AS "Date",
  "h_name" || ' vs ' || "a_name" AS "Matchup or Venue",
  TO_CHAR(ROUND("h_three_points_made" + "a_three_points_made", 4), 'FM9999999.0000') AS "Key Metric"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
WHERE "h_three_points_made" IS NOT NULL AND "a_three_points_made" IS NOT NULL
ORDER BY ("h_three_points_made" + "a_three_points_made") DESC NULLS LAST
LIMIT 5
)