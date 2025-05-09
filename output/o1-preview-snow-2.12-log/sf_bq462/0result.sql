WITH largest_venues AS (
    SELECT 
        'Largest Venues' AS "Category",
        'N/A' AS "Date",
        "venue_name" AS "Matchup or Venue",
        CAST(MAX("venue_capacity") AS INT) AS "Key Metric"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "venue_capacity" IS NOT NULL
    GROUP BY "venue_name"
    ORDER BY "Key Metric" DESC NULLS LAST
    LIMIT 5
),
biggest_championship_margins AS (
    SELECT 
        'Biggest Championship Margins' AS "Category",
        TO_VARCHAR("game_date", 'YYYY-MM-DD') AS "Date",
        CONCAT("win_name", ' vs ', "lose_name") AS "Matchup or Venue",
        CAST(("win_pts" - "lose_pts") AS INT) AS "Key Metric"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2015 AND "round" = 2
    ORDER BY "Key Metric" DESC NULLS LAST
    LIMIT 5
),
highest_scoring_games AS (
    SELECT 
        'Highest Scoring Games' AS "Category",
        TO_VARCHAR("scheduled_date", 'YYYY-MM-DD') AS "Date",
        CONCAT("h_name", ' vs ', "a_name") AS "Matchup or Venue",
        CAST(("h_points_game" + "a_points_game") AS INT) AS "Key Metric"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" >= 2010 AND "h_points_game" IS NOT NULL AND "a_points_game" IS NOT NULL
    ORDER BY "Key Metric" DESC NULLS LAST
    LIMIT 5
),
most_three_pointers AS (
    SELECT 
        'Most Three-Pointers in a Matchup' AS "Category",
        TO_VARCHAR("scheduled_date", 'YYYY-MM-DD') AS "Date",
        CONCAT("h_name", ' vs ', "a_name") AS "Matchup or Venue",
        CAST(("h_three_points_made" + "a_three_points_made") AS INT) AS "Key Metric"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" >= 2010 AND "h_three_points_made" IS NOT NULL AND "a_three_points_made" IS NOT NULL
    ORDER BY "Key Metric" DESC NULLS LAST
    LIMIT 5
)
SELECT * FROM largest_venues
UNION ALL
SELECT * FROM biggest_championship_margins
UNION ALL
SELECT * FROM highest_scoring_games
UNION ALL
SELECT * FROM most_three_pointers;