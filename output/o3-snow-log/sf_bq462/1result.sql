/*  Top-5 lists for four different categories                                  */
/*  Columns returned:  CATEGORY | DATE | MATCHUP_OR_VENUE | KEY_METRIC         */

WITH

/* -------------------------------------------------------------------------- */
/* 1)  TOP VENUES – biggest arenas (capacity) – Date forced to 'N/A'          */
top_venues AS (
    SELECT
        'Top Venues'                                              AS CATEGORY,
        'N/A'                                                     AS DATE,
        /*  show venue, city, state for readability                              */
        CONCAT_WS(' - ',
                  COALESCE("venue_name", 'Unknown'),
                  COALESCE("venue_city", 'Unknown'),
                  COALESCE("venue_state", ''))                    AS MATCHUP_OR_VENUE,
        MAX("venue_capacity")                                     AS KEY_METRIC
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "venue_capacity" IS NOT NULL
    GROUP BY "venue_name", "venue_city", "venue_state"
    QUALIFY ROW_NUMBER() OVER (ORDER BY MAX("venue_capacity") DESC) <= 5
),

/* -------------------------------------------------------------------------- */
/* 2)  BIGGEST CHAMPIONSHIP MARGINS – NCAA title games since 2016             */
champ_margins AS (
    SELECT
        'Biggest Championship Margins'                             AS CATEGORY,
        TO_CHAR("scheduled_date",'YYYY-MM-DD')                     AS DATE,
        CONCAT_WS(' vs ',
                  CONCAT_WS(' ', COALESCE("a_market",''), COALESCE("a_name",'')),
                  CONCAT_WS(' ', COALESCE("h_market",''), COALESCE("h_name",''))) AS MATCHUP_OR_VENUE,
        ABS("a_points" - "h_points")                               AS KEY_METRIC
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2015
      AND UPPER(COALESCE("tournament",''))      = 'NCAA'
      AND UPPER(COALESCE("tournament_round",'')) LIKE '%CHAMPIONSHIP%'   -- catches 'National Championship'
      AND "a_points" IS NOT NULL
      AND "h_points" IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (ORDER BY ABS("a_points" - "h_points") DESC) <= 5
),

/* -------------------------------------------------------------------------- */
/* 3)  HIGHEST SCORING GAMES – total points since 2011                        */
high_scores AS (
    SELECT
        'Highest Scoring Games'                                    AS CATEGORY,
        TO_CHAR("scheduled_date",'YYYY-MM-DD')                     AS DATE,
        CONCAT_WS(' vs ',
                  CONCAT_WS(' ', COALESCE("a_market",''), COALESCE("a_name",'')),
                  CONCAT_WS(' ', COALESCE("h_market",''), COALESCE("h_name",''))) AS MATCHUP_OR_VENUE,
        ("a_points" + "h_points")                                  AS KEY_METRIC
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010
      AND "a_points" IS NOT NULL
      AND "h_points" IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (ORDER BY ("a_points" + "h_points") DESC) <= 5
),

/* -------------------------------------------------------------------------- */
/* 4)  TOTAL THREES – most 3-pointers made (both teams) since 2011            */
total_threes AS (
    SELECT
        'Total Threes'                                             AS CATEGORY,
        TO_CHAR("scheduled_date",'YYYY-MM-DD')                     AS DATE,
        CONCAT_WS(' vs ',
                  CONCAT_WS(' ', COALESCE("a_market",''), COALESCE("a_name",'')),
                  CONCAT_WS(' ', COALESCE("h_market",''), COALESCE("h_name",''))) AS MATCHUP_OR_VENUE,
        ("a_three_points_made" + "h_three_points_made")            AS KEY_METRIC
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010
      AND "a_three_points_made" IS NOT NULL
      AND "h_three_points_made" IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (ORDER BY ("a_three_points_made" + "h_three_points_made") DESC) <= 5
)

/* -------------------------------------------------------------------------- */
SELECT *
FROM (
        SELECT * FROM top_venues
        UNION ALL
        SELECT * FROM champ_margins
        UNION ALL
        SELECT * FROM high_scores
        UNION ALL
        SELECT * FROM total_threes
     )
ORDER BY CATEGORY,
         KEY_METRIC DESC NULLS LAST;