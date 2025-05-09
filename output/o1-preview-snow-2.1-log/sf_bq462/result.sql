WITH MaxRounds AS (
    SELECT "season", MIN("round") AS "championship_round"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2015
    GROUP BY "season"
),
ChampionshipGames AS (
    SELECT htg."game_date", htg."win_name", htg."lose_name", htg."win_pts", htg."lose_pts",
           ("win_pts" - "lose_pts") AS "margin"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES htg
    JOIN MaxRounds mr ON htg."season" = mr."season" AND htg."round" = mr."championship_round"
    WHERE htg."win_pts" IS NOT NULL AND htg."lose_pts" IS NOT NULL
),
LargestVenues AS (
    SELECT 'Largest Venues' AS "Category",
        'N/A' AS "Date",
        "venue_name" AS "Matchup or Venue",
        CAST("venue_capacity" AS INT) AS "Key Metric",
        ROW_NUMBER() OVER (ORDER BY CAST("venue_capacity" AS INT) DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_TEAMS
    WHERE "venue_name" IS NOT NULL AND "venue_capacity" IS NOT NULL
        AND "venue_capacity" > 0
    GROUP BY "venue_name", "venue_capacity"
),
BiggestMargins AS (
    SELECT 'Biggest Championship Margins since 2015' AS "Category",
        TO_CHAR(cg."game_date", 'YYYY-MM-DD') AS "Date",
        cg."win_name" || ' vs ' || cg."lose_name" AS "Matchup or Venue",
        cg."margin" AS "Key Metric",
        ROW_NUMBER() OVER (ORDER BY cg."margin" DESC NULLS LAST) AS rn
    FROM ChampionshipGames cg
),
HighestScoringGames AS (
    SELECT 'Highest Scoring Games' AS "Category",
        TO_CHAR("scheduled_date", 'YYYY-MM-DD') AS "Date",
        "h_name" || ' vs ' || "a_name" AS "Matchup or Venue",
        ("h_points_game" + "a_points_game") AS "Key Metric",
        ROW_NUMBER() OVER (ORDER BY ("h_points_game" + "a_points_game") DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" >= 2010
        AND "h_points_game" IS NOT NULL AND "a_points_game" IS NOT NULL
),
MostThreePointers AS (
    SELECT 'Most Three-Pointers in a Matchup' AS "Category",
        TO_CHAR(t1."scheduled_date", 'YYYY-MM-DD') AS "Date",
        t1."name" || ' vs ' || t2."name" AS "Matchup or Venue",
        (t1."three_points_made" + t2."three_points_made") AS "Key Metric",
        ROW_NUMBER() OVER (ORDER BY (t1."three_points_made" + t2."three_points_made") DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_TEAMS_GAMES_SR t1
    JOIN NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_TEAMS_GAMES_SR t2
        ON t1."game_id" = t2."game_id" AND t1."team_id" < t2."team_id"
    WHERE t1."season" >= 2010
        AND t1."three_points_made" IS NOT NULL AND t2."three_points_made" IS NOT NULL
)
SELECT "Category", "Date", "Matchup or Venue", "Key Metric"
FROM (
    SELECT "Category", "Date", "Matchup or Venue", "Key Metric", rn FROM LargestVenues WHERE rn <= 5
    UNION ALL
    SELECT "Category", "Date", "Matchup or Venue", "Key Metric", rn FROM BiggestMargins WHERE rn <= 5
    UNION ALL
    SELECT "Category", "Date", "Matchup or Venue", "Key Metric", rn FROM HighestScoringGames WHERE rn <=5
    UNION ALL
    SELECT "Category", "Date", "Matchup or Venue", "Key Metric", rn FROM MostThreePointers WHERE rn <=5
) AS combined
ORDER BY
    CASE "Category"
        WHEN 'Largest Venues' THEN 1
        WHEN 'Biggest Championship Margins since 2015' THEN 2
        WHEN 'Highest Scoring Games' THEN 3
        WHEN 'Most Three-Pointers in a Matchup' THEN 4
        ELSE 5
    END,
    CAST("Key Metric" AS INT) DESC NULLS LAST;