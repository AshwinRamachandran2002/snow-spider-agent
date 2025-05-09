WITH
/* ---------- 1.  Top Venues ---------- */
venue_caps AS (
    SELECT
        "venue_id",
        MAX("venue_capacity") AS capacity,
        MAX("venue_name")  AS venue_name,
        MAX("venue_city")  AS venue_city,
        MAX("venue_state") AS venue_state
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_GAMES_SR"
    WHERE "venue_capacity" IS NOT NULL
    GROUP BY "venue_id"
),
top_venues5 AS (
    SELECT
        'Top Venues'                                           AS Category,
        'N/A'                                                  AS Date,
        CONCAT(venue_name, ' (', venue_city, ', ', venue_state, ')') AS "Matchup_or_Venue",
        capacity                                               AS "Key_Metric",
        ROW_NUMBER() OVER (ORDER BY capacity DESC)             AS rn
    FROM venue_caps
)
/* ---------- 2.  Biggest Championship Margins ---------- */
,champ_margins AS (
    SELECT
        "game_date",
        "win_market",
        "win_name",
        "win_pts",
        "lose_market",
        "lose_name",
        "lose_pts",
        ABS("win_pts" - "lose_pts")            AS margin
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_HISTORICAL_TOURNAMENT_GAMES"
    WHERE "season" > 2015              -- seasons 2016+
      AND "round"  = 2                 -- National Championship (2 teams left)
      AND "win_pts"  IS NOT NULL
      AND "lose_pts" IS NOT NULL
),
champ_margins5 AS (
    SELECT
        'Biggest Championship Margins'                                           AS Category,
        TO_CHAR("game_date", 'YYYY-MM-DD')                                       AS Date,
        CONCAT("win_market",' ', "win_name",' ', "win_pts",
               ' - ', "lose_pts",' ', "lose_market",' ', "lose_name")            AS "Matchup_or_Venue",
        margin                                                                   AS "Key_Metric",
        ROW_NUMBER() OVER (ORDER BY margin DESC)                                 AS rn
    FROM champ_margins
)
/* ---------- 3.  Highest Scoring Games ---------- */
,scoring_games AS (
    SELECT
        "scheduled_date",
        "a_market", "a_name", "a_points",
        "h_market", "h_name", "h_points",
        ("a_points" + "h_points")                      AS total_pts
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_GAMES_SR"
    WHERE "season" > 2010
      AND "a_points" IS NOT NULL
      AND "h_points" IS NOT NULL
),
high_scoring5 AS (
    SELECT
        'Highest Scoring Games'                                                    AS Category,
        TO_CHAR("scheduled_date", 'YYYY-MM-DD')                                    AS Date,
        CONCAT("a_market",' ', "a_name",' ', "a_points",
               ' - ', "h_points",' ', "h_market",' ', "h_name")                    AS "Matchup_or_Venue",
        total_pts                                                                  AS "Key_Metric",
        ROW_NUMBER() OVER (ORDER BY total_pts DESC)                                AS rn
    FROM scoring_games
)
/* ---------- 4.  Total Threes ---------- */
,threes_games AS (
    SELECT
        "scheduled_date",
        "a_market", "a_name",
        "h_market", "h_name",
        COALESCE("a_three_points_made",0) + COALESCE("h_three_points_made",0) AS total_threes
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_GAMES_SR"
    WHERE "season" > 2010
      AND "a_three_points_made" IS NOT NULL
      AND "h_three_points_made" IS NOT NULL
),
total_threes5 AS (
    SELECT
        'Total Threes'                                                            AS Category,
        TO_CHAR("scheduled_date", 'YYYY-MM-DD')                                   AS Date,
        CONCAT("a_market",' ', "a_name",' vs ', "h_market",' ', "h_name")         AS "Matchup_or_Venue",
        total_threes                                                              AS "Key_Metric",
        ROW_NUMBER() OVER (ORDER BY total_threes DESC)                            AS rn
    FROM threes_games
)

/* ---------- Final Union of the four top-5 lists ---------- */
SELECT Category, Date, "Matchup_or_Venue", "Key_Metric"
FROM (
    SELECT Category, Date, "Matchup_or_Venue", "Key_Metric"
    FROM top_venues5
    WHERE rn <= 5

    UNION ALL

    SELECT Category, Date, "Matchup_or_Venue", "Key_Metric"
    FROM champ_margins5
    WHERE rn <= 5

    UNION ALL

    SELECT Category, Date, "Matchup_or_Venue", "Key_Metric"
    FROM high_scoring5
    WHERE rn <= 5

    UNION ALL

    SELECT Category, Date, "Matchup_or_Venue", "Key_Metric"
    FROM total_threes5
    WHERE rn <= 5
)
ORDER BY Category, "Key_Metric" DESC NULLS LAST;