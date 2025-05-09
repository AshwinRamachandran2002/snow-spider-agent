/*  Top-5 records for four different categories                         */
/*  Columns returned:                                                   */
/*    Category | Date | Matchup or Venue | Key Metric                   */

WITH
/* ------------------------------------------------------------- */
/* 1)  Top Venues – biggest seating capacities (date = 'N/A')    */
top_venues AS (
    SELECT
        'Top Venues'                                           AS category,
        'N/A'                                                  AS date,
        CONCAT(COALESCE("venue_name",'Unknown'),
               ' (', COALESCE("venue_city",''),
               CASE WHEN "venue_state" IS NOT NULL
                    THEN CONCAT(', ', "venue_state") ELSE '' END,
               ')')                                            AS matchup_or_venue,
        MAX("venue_capacity")                                  AS key_metric
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE  "venue_capacity" IS NOT NULL
    GROUP  BY "venue_id","venue_name","venue_city","venue_state"
    ORDER  BY key_metric DESC
    LIMIT  5
),

/* ------------------------------------------------------------- */
/* 2)  Biggest Championship Margins – NCAA title games (round=2) */
champ_margins AS (
    SELECT
        'Biggest Championship Margins'                         AS category,
        TO_CHAR("game_date",'YYYY-MM-DD')                      AS date,
        CONCAT("win_market",' ', "win_name",
               ' vs ',
               "lose_market",' ', "lose_name")                 AS matchup_or_venue,
        ("win_pts" - "lose_pts")                               AS key_metric
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE  "season" > 2015        -- seasons 2016+
      AND  "round"  = 2           -- National Championship
    ORDER  BY key_metric DESC NULLS LAST
    LIMIT  5
),

/* ------------------------------------------------------------- */
/* 3)  Highest Scoring Games – since 2011                        */
high_scoring AS (
    SELECT
        'Highest Scoring Games'                                AS category,
        TO_CHAR("scheduled_date",'YYYY-MM-DD')                 AS date,
        CONCAT("a_market",' ', "a_name",
               ' vs ',
               "h_market",' ', "h_name")                       AS matchup_or_venue,
        ("a_points" + "h_points")                              AS key_metric
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE  "season" > 2010
      AND  "a_points" IS NOT NULL
      AND  "h_points" IS NOT NULL
    ORDER  BY key_metric DESC NULLS LAST
    LIMIT  5
),

/* ------------------------------------------------------------- */
/* 4)  Total Threes – most combined 3-pointers since 2011        */
total_threes AS (
    SELECT
        'Total Threes'                                         AS category,
        TO_CHAR("scheduled_date",'YYYY-MM-DD')                 AS date,
        CONCAT("a_market",' ', "a_name",
               ' vs ',
               "h_market",' ', "h_name")                       AS matchup_or_venue,
        ("a_three_points_made" + "h_three_points_made")        AS key_metric
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE  "season" > 2010
      AND  "a_three_points_made" IS NOT NULL
      AND  "h_three_points_made" IS NOT NULL
    ORDER  BY key_metric DESC NULLS LAST
    LIMIT  5
)

/* ------------------------------------------------------------- */
/*  Final union of the four categories                           */
SELECT
    category       AS "Category",
    date           AS "Date",
    matchup_or_venue AS "Matchup or Venue",
    key_metric     AS "Key Metric"
FROM (
      SELECT * FROM top_venues
      UNION ALL
      SELECT * FROM champ_margins
      UNION ALL
      SELECT * FROM high_scoring
      UNION ALL
      SELECT * FROM total_threes
) AS combined
ORDER BY
    CASE category
         WHEN 'Top Venues'                  THEN 1
         WHEN 'Biggest Championship Margins' THEN 2
         WHEN 'Highest Scoring Games'       THEN 3
         WHEN 'Total Threes'                THEN 4
    END,
    key_metric DESC;