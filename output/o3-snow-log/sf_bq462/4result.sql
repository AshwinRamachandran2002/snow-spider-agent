/* -----------------------------------------------------------
   Consolidated table with the TOP-5 records for each category:
     ① Top Venues (largest capacities – Date shown as N/A)
     ② Biggest Championship Margins   (season > 2015)
     ③ Highest Scoring Games          (season > 2010)
     ④ Total Threes                   (season > 2010)
   ----------------------------------------------------------- */

WITH
/* ---------- ①  Top Venues ---------- */
top_venues AS (
    SELECT
        'Top Venues'                                           AS category ,
        'N/A'                                                  AS dt ,
        CONCAT(MAX("venue_name"), ' (',
               MAX("venue_city"), ', ', MAX("venue_state"), ')')
                                                              AS matchup_or_venue ,
        MAX("venue_capacity")                                  AS key_metric ,
        ROW_NUMBER() OVER (ORDER BY MAX("venue_capacity") DESC NULLS LAST) AS rn
    FROM  NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "venue_capacity" IS NOT NULL
    GROUP BY "venue_id"
    QUALIFY rn <= 5
),

/* ---------- ②  Biggest Championship Margins (since 2016) ---------- */
champ_margins AS (
    SELECT
        'Biggest Championship Margins'                         AS category ,
        TO_CHAR("scheduled_date", 'YYYY-MM-DD')                AS dt ,
        CONCAT(COALESCE("a_market",''), ' ', COALESCE("a_name",''), ' vs ',
               COALESCE("h_market",''), ' ', COALESCE("h_name",''))
                                                              AS matchup_or_venue ,
        ABS(COALESCE("h_points_game",0) - COALESCE("a_points_game",0))
                                                              AS key_metric ,
        ROW_NUMBER() OVER (
            ORDER BY ABS(COALESCE("h_points_game",0) - COALESCE("a_points_game",0)) DESC NULLS LAST
        ) AS rn
    FROM  NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2015
      AND ( "tournament_round" ILIKE '%championship%'
         OR "tournament_type"  ILIKE '%championship%' )
      AND "h_points_game" IS NOT NULL
      AND "a_points_game" IS NOT NULL
    QUALIFY rn <= 5
),

/* ---------- ③  Highest Scoring Games (since 2011) ---------- */
high_scores AS (
    SELECT
        'Highest Scoring Games'                                AS category ,
        TO_CHAR("scheduled_date", 'YYYY-MM-DD')                AS dt ,
        CONCAT(COALESCE("a_market",''), ' ', COALESCE("a_name",''), ' vs ',
               COALESCE("h_market",''), ' ', COALESCE("h_name",''))
                                                              AS matchup_or_venue ,
        (COALESCE("a_points_game",0) + COALESCE("h_points_game",0))
                                                              AS key_metric ,
        ROW_NUMBER() OVER (
            ORDER BY (COALESCE("a_points_game",0) + COALESCE("h_points_game",0)) DESC NULLS LAST
        ) AS rn
    FROM  NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010
      AND "a_points_game" IS NOT NULL
      AND "h_points_game" IS NOT NULL
    QUALIFY rn <= 5
),

/* ---------- ④  Total Threes (since 2011) ---------- */
total_threes AS (
    SELECT
        'Total Threes'                                         AS category ,
        TO_CHAR("scheduled_date", 'YYYY-MM-DD')                AS dt ,
        CONCAT(COALESCE("a_market",''), ' ', COALESCE("a_name",''), ' vs ',
               COALESCE("h_market",''), ' ', COALESCE("h_name",''))
                                                              AS matchup_or_venue ,
        (COALESCE("a_three_points_made",0) + COALESCE("h_three_points_made",0))
                                                              AS key_metric ,
        ROW_NUMBER() OVER (
            ORDER BY (COALESCE("a_three_points_made",0) + COALESCE("h_three_points_made",0)) DESC NULLS LAST
        ) AS rn
    FROM  NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010
      AND ( "a_three_points_made" IS NOT NULL
         OR "h_three_points_made" IS NOT NULL )
    QUALIFY rn <= 5
)

/* ---------- Final union of the four categories ---------- */
SELECT  category              AS "Category",
        dt                    AS "Date",
        matchup_or_venue      AS "Matchup or Venue",
        key_metric            AS "Key Metric"
FROM (
    SELECT * FROM top_venues
    UNION ALL
    SELECT * FROM champ_margins
    UNION ALL
    SELECT * FROM high_scores
    UNION ALL
    SELECT * FROM total_threes
)
ORDER BY "Category", "Key Metric" DESC NULLS LAST;