/*---------------------------------------------------------------------*
 | Top-5 rows for each requested NCAA men’s basketball category        |
 *---------------------------------------------------------------------*/
WITH
/*---------------------------------------------------------------------*
 | 1) Largest venues (capacity)                                        |
 *---------------------------------------------------------------------*/
top_venues AS (
  SELECT
    'Top Venues'                                                   AS Category,
    'N/A'                                                          AS Date,
    CONCAT(venue_name,' – ',venue_city,', ',venue_state)           AS `Matchup or Venue`,
    venue_capacity                                                 AS `Key Metric`,
    ROW_NUMBER() OVER (ORDER BY venue_capacity DESC)               AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_teams`
  WHERE venue_capacity IS NOT NULL
  GROUP BY venue_name, venue_city, venue_state, venue_capacity
),
/*---------------------------------------------------------------------*
 | 2) Biggest national-championship winning margins since 2016         |
 *---------------------------------------------------------------------*/
champ_margins AS (
  SELECT
    'Biggest Championship Margins'                                  AS Category,
    FORMAT_DATE('%Y-%m-%d', game_date)                               AS Date,
    CONCAT(win_market,' ',win_name,' vs. ',lose_market,' ',lose_name) AS `Matchup or Venue`,
    (win_pts - lose_pts)                                             AS `Key Metric`,
    ROW_NUMBER() OVER (ORDER BY win_pts - lose_pts DESC)             AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season > 2015
    AND round = 2          -- 2-team championship game
),
/*---------------------------------------------------------------------*
 | 3) Highest scoring games (combined points) since 2011               |
 *---------------------------------------------------------------------*/
high_scores AS (
  SELECT
    'Highest Scoring Games'                                          AS Category,
    FORMAT_DATE('%Y-%m-%d', scheduled_date)                          AS Date,
    CONCAT(a_market,' ',a_name,' @ ',h_market,' ',h_name)            AS `Matchup or Venue`,
    (h_points + a_points)                                            AS `Key Metric`,
    ROW_NUMBER() OVER (ORDER BY h_points + a_points DESC)            AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
),
/*---------------------------------------------------------------------*
 | 4) Games with most made 3-pointers (combined) since 2011            |
 *---------------------------------------------------------------------*/
total_threes AS (
  SELECT
    'Total Threes'                                                   AS Category,
    FORMAT_DATE('%Y-%m-%d', scheduled_date)                          AS Date,
    CONCAT(a_market,' ',a_name,' @ ',h_market,' ',h_name)            AS `Matchup or Venue`,
    (h_three_points_made + a_three_points_made)                      AS `Key Metric`,
    ROW_NUMBER() OVER (ORDER BY h_three_points_made + a_three_points_made DESC) AS rn
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season > 2010
)
/*---------------------------------------------------------------------*
 | Combine the four result sets                                        |
 *---------------------------------------------------------------------*/
SELECT Category,
       Date,
       `Matchup or Venue`,
       `Key Metric`
FROM (
  SELECT * FROM top_venues   WHERE rn <= 5
  UNION ALL
  SELECT * FROM champ_margins WHERE rn <= 5
  UNION ALL
  SELECT * FROM high_scores   WHERE rn <= 5
  UNION ALL
  SELECT * FROM total_threes  WHERE rn <= 5
)
ORDER BY Category, `Key Metric` DESC;