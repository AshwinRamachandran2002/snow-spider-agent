/*  Four top-5 lists combined into one result table                                       
    ---------------------------------------------------------------------------
    Category order:
      1. Top Venues – largest seating capacity (Date shown as 'N/A')
      2. Biggest Championship Margins – NCAA title games (round = 2) since 2016
      3. Highest Scoring Games – since 2011, highest combined points
      4. Total Threes – since 2011, highest combined 3-pt FG made
    ---------------------------------------------------------------------------
*/
WITH
/* ---------------------------------------------------- */
top_venues AS (
    SELECT
        'Top Venues'                               AS category ,
        'N/A'                                      AS date ,
        CONCAT("venue_name",
               ' (', COALESCE("venue_city",''), ', ',
                     COALESCE("venue_state",''), ')')         
                                                   AS matchup_or_venue ,
        MAX("venue_capacity")                      AS key_metric ,
        ROW_NUMBER() OVER (ORDER BY MAX("venue_capacity") DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "venue_capacity" IS NOT NULL
    GROUP BY "venue_name","venue_city","venue_state"
),    
/* ---------------------------------------------------- */
champ_margins AS (
    SELECT
        'Biggest Championship Margins'             AS category ,
        TO_CHAR("game_date",'YYYY-MM-DD')          AS date ,
        CONCAT("win_market",' ', "win_name",
               ' vs ',
               "lose_market",' ', "lose_name")     AS matchup_or_venue ,
        ("win_pts" - "lose_pts")                   AS key_metric ,
        ROW_NUMBER() OVER (ORDER BY ("win_pts" - "lose_pts") DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" > 2015            -- 2016 season onward
      AND "round"  = 2               -- National Championship game
),    
/* ---------------------------------------------------- */
high_scoring AS (
    SELECT
        'Highest Scoring Games'                    AS category ,
        TO_CHAR("scheduled_date",'YYYY-MM-DD')     AS date ,
        CONCAT(COALESCE("a_market",'Unknown'),' ',COALESCE("a_name",''),
               ' vs ',
               COALESCE("h_market",'Unknown'),' ',COALESCE("h_name",'')) 
                                                   AS matchup_or_venue ,
        ("a_points" + "h_points")                  AS key_metric ,
        ROW_NUMBER() OVER (ORDER BY ("a_points" + "h_points") DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010          -- 2011 season onward
),    
/* ---------------------------------------------------- */
total_threes AS (
    SELECT
        'Total Threes'                             AS category ,
        TO_CHAR("scheduled_date",'YYYY-MM-DD')     AS date ,
        CONCAT(COALESCE("a_market",'Unknown'),' ',COALESCE("a_name",''),
               ' vs ',
               COALESCE("h_market",'Unknown'),' ',COALESCE("h_name",'')) 
                                                   AS matchup_or_venue ,
        ("a_three_points_made" + "h_three_points_made")  AS key_metric ,
        ROW_NUMBER() OVER (ORDER BY ("a_three_points_made" + "h_three_points_made") DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010          -- 2011 season onward
)
/* ==================================================== */
SELECT
    category                           AS "Category" ,
    date                               AS "Date" ,
    matchup_or_venue                   AS "Matchup or Venue" ,
    key_metric                         AS "Key Metric"
FROM (
      SELECT * FROM top_venues     WHERE rn <= 5
      UNION ALL
      SELECT * FROM champ_margins  WHERE rn <= 5
      UNION ALL
      SELECT * FROM high_scoring   WHERE rn <= 5
      UNION ALL
      SELECT * FROM total_threes   WHERE rn <= 5
) AS combined
ORDER BY
    CASE category
        WHEN 'Top Venues'                 THEN 1
        WHEN 'Biggest Championship Margins' THEN 2
        WHEN 'Highest Scoring Games'        THEN 3
        WHEN 'Total Threes'                 THEN 4
    END,
    rn;