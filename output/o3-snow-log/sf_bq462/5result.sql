/*  Top-5 records for each requested category                                     */
/*  ----------------------------------------------------------------------------  */
/*  Columns returned:                                                             */
/*  1) CATEGORY          – the section this row belongs to                        */
/*  2) DATE              – game date (or ‘N/A’ for the venue list)                */
/*  3) MATCHUP_OR_VENUE  – game matchup text or venue description                 */
/*  4) KEY_METRIC        – value that the ranking is based on                     */

WITH

/* ---------- 1.  Top Venues ---------------------------------------------------- */
top_venues AS (
    SELECT
        'Top Venues'                                                             AS category,
        'N/A'                                                                    AS date,
        CONCAT("venue_name", ' (', "venue_city", ', ', "venue_state", ')')       AS matchup_or_venue,
        MAX("venue_capacity")                                                    AS key_metric
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "venue_capacity" IS NOT NULL
    GROUP BY "venue_name", "venue_city", "venue_state"
    QUALIFY ROW_NUMBER() OVER (ORDER BY key_metric DESC NULLS LAST) <= 5
),

/* ---------- 2.  Biggest Championship Margins --------------------------------- */
champ_margins AS (
    SELECT
        'Biggest Championship Margins'                                           AS category,
        TO_VARCHAR("scheduled_date")                                             AS date,
        CONCAT("a_market", ' ', "a_name", ' vs ', "h_market", ' ', "h_name")     AS matchup_or_venue,
        ABS("a_points" - "h_points")                                             AS key_metric
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2015
      AND UPPER("tournament_round") LIKE '%NATIONAL%'        -- National Championship games
      AND "a_points" IS NOT NULL
      AND "h_points" IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (ORDER BY key_metric DESC NULLS LAST) <= 5
),

/* ---------- 3.  Highest Scoring Games ---------------------------------------- */
high_scoring AS (
    SELECT
        'Highest Scoring Games'                                                  AS category,
        TO_VARCHAR("scheduled_date")                                             AS date,
        CONCAT("a_market", ' ', "a_name", ' vs ', "h_market", ' ', "h_name")     AS matchup_or_venue,
        ("a_points" + "h_points")                                                AS key_metric
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010
      AND "a_points" IS NOT NULL
      AND "h_points" IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (ORDER BY key_metric DESC NULLS LAST) <= 5
),

/* ---------- 4.  Most Three-Pointers Made ------------------------------------- */
most_threes AS (
    SELECT
        'Total Threes'                                                           AS category,
        TO_VARCHAR("scheduled_date")                                             AS date,
        CONCAT("a_market", ' ', "a_name", ' vs ', "h_market", ' ', "h_name")     AS matchup_or_venue,
        ("a_three_points_made" + "h_three_points_made")                          AS key_metric
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010
      AND "a_three_points_made" IS NOT NULL
      AND "h_three_points_made" IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (ORDER BY key_metric DESC NULLS LAST) <= 5
)

/* ---------- Combine all four sections --------------------------------------- */
SELECT * FROM top_venues
UNION ALL
SELECT * FROM champ_margins
UNION ALL
SELECT * FROM high_scoring
UNION ALL
SELECT * FROM most_threes
ORDER BY category, key_metric DESC NULLS LAST;