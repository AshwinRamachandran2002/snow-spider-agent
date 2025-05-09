-- Top‑5 markets by count of distinct players who scored ≥15 points
-- in the 2nd period of any game (seasons 2010‑2018),
-- and every NCAA tournament game (2010‑2018) in which those markets appeared
WITH second_period_player_totals AS (
  SELECT
    team_market,
    player_id,
    SUM(points_scored) AS pts_2nd_period
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE
    season BETWEEN 2010 AND 2018
    AND period = 2
    AND points_scored IS NOT NULL
    AND NOT IS_NAN(points_scored)
  GROUP BY team_market, player_id
  HAVING pts_2nd_period >= 15
),
market_player_counts AS (
  SELECT
    team_market,
    COUNT(DISTINCT player_id) AS distinct_players
  FROM second_period_player_totals
  GROUP BY team_market
),
top5_markets AS (
  SELECT team_market
  FROM market_player_counts
  ORDER BY distinct_players DESC, team_market
  LIMIT 5
),
tourney_games_2010_18 AS (
  SELECT *
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
),
games_with_focus_market AS (
  -- games where the focus market won
  SELECT
    m.team_market                                     AS focus_market,
    tg.*
  FROM tourney_games_2010_18 tg
  JOIN top5_markets m
    ON tg.win_market = m.team_market

  UNION ALL

  -- games where the focus market lost
  SELECT
    m.team_market                                     AS focus_market,
    tg.*
  FROM tourney_games_2010_18 tg
  JOIN top5_markets m
    ON tg.lose_market = m.team_market
)
SELECT
  focus_market                                       AS team_market,
  season,
  round,
  game_date,
  day,
  win_seed,
  win_region,
  win_market,
  win_name,
  win_alias,
  win_pts,
  lose_seed,
  lose_region,
  lose_market,
  lose_name,
  lose_alias,
  lose_pts,
  num_ot
FROM games_with_focus_market
ORDER BY team_market, season, game_date;