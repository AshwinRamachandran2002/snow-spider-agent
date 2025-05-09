/*  NCAA‑MEN  |  BigQuery
    ------------------------------------------------------------------
    For seasons 2010‑2018:
      1.  Find the five team‑markets that had the most DISTINCT players
          score ≥15 points in the 2nd period of any game (play‑by‑play).
      2.  Return every NCAA‑tournament game (same seasons) in which any
          of those five markets took part, expressed from that market’s
          point‑of‑view and shaped exactly like the data‑model spec.
*/
WITH second_half_15 AS (          -- every player‑game with 15+ pts in period 2
  SELECT DISTINCT player_id, team_market
  FROM (
    SELECT
      season,
      game_id,
      player_id,
      team_market,
      SUM(IFNULL(points_scored,0)) AS pts_2nd_period
    FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
    WHERE season BETWEEN 2010 AND 2018
      AND period = 2
    GROUP BY season, game_id, player_id, team_market
  )
  WHERE pts_2nd_period >= 15
),
top5_markets AS (                 -- five markets with the most such players
  SELECT team_market
  FROM second_half_15
  GROUP BY team_market
  ORDER BY COUNT(DISTINCT player_id) DESC
  LIMIT 5
),
tourney AS (                      -- limit tournament rows to the season window
  SELECT *
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
)

--  -------  perspective of the winning team (if it is a top‑5 market)  -------
SELECT
  season,
  `round`,
  days_from_epoch,
  game_date,
  `day`,
  'win'                                      AS label,
  win_seed                                   AS seed,
  win_market                                 AS market,
  win_name                                   AS name,
  win_alias                                  AS alias,
  win_school_ncaa                            AS school_ncaa,
  lose_seed                                  AS opponent_seed,
  lose_market                                AS opponent_market,
  lose_name                                  AS opponent_name,
  lose_alias                                 AS opponent_alias,
  lose_school_ncaa                           AS opponent_school_ncaa
FROM tourney
WHERE win_market IN (SELECT team_market FROM top5_markets)

UNION ALL

--  -------  perspective of the losing team (if it is a top‑5 market)  -------
SELECT
  season,
  `round`,
  days_from_epoch,
  game_date,
  `day`,
  'loss'                                     AS label,
  lose_seed                                  AS seed,
  lose_market                                AS market,
  lose_name                                  AS name,
  lose_alias                                 AS alias,
  lose_school_ncaa                           AS school_ncaa,
  win_seed                                   AS opponent_seed,
  win_market                                 AS opponent_market,
  win_name                                   AS opponent_name,
  win_alias                                  AS opponent_alias,
  win_school_ncaa                            AS opponent_school_ncaa
FROM tourney
WHERE lose_market IN (SELECT team_market FROM top5_markets)

ORDER BY season, game_date, market, label;