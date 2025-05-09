/* --------------------------------------------------------------------------
   1. Identify players who scored 15+ points in 2nd period (2010‑2018)
   2. Keep the five team markets with the most such DISTINCT players
   3. Return every NCAA‑tournament game (2010‑2018) those markets played,
      expressed as one row per team‑appearance with the columns described
      in the data‑model documentation.
---------------------------------------------------------------------------*/
WITH player_second_period AS (          -- players with ≥15 pts in period 2
  SELECT
    team_market               AS market,
    player_id,
    SUM(COALESCE(points_scored,0)) AS pts_p2
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2
    AND player_id IS NOT NULL
  GROUP BY market, player_id
  HAVING pts_p2 >= 15
),
player_counts AS (                      -- count of such players per market
  SELECT
    market,
    COUNT(DISTINCT player_id) AS distinct_players
  FROM player_second_period
  GROUP BY market
),
top5_markets AS (                       -- the five biggest markets
  SELECT market
  FROM player_counts
  ORDER BY distinct_players DESC, market
  LIMIT 5
),
tourney_long AS (                       -- unpivot wins / losses to one row
  SELECT
    season,
    `round`,
    game_date,
    day,
    'win'                           AS label,
    win_seed                        AS seed,
    win_market                      AS market,
    win_name                        AS name,
    win_alias                       AS team_alias,
    win_school_ncaa                 AS school_ncaa,
    lose_seed                       AS opponent_seed,
    lose_market                     AS opponent_market,
    lose_name                       AS opponent_name,
    lose_alias                      AS opponent_alias,
    lose_school_ncaa                AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018

  UNION ALL

  SELECT
    season,
    `round`,
    game_date,
    day,
    'loss'                          AS label,
    lose_seed                       AS seed,
    lose_market                     AS market,
    lose_name                       AS name,
    lose_alias                      AS team_alias,
    lose_school_ncaa                AS school_ncaa,
    win_seed                        AS opponent_seed,
    win_market                      AS opponent_market,
    win_name                        AS opponent_name,
    win_alias                       AS opponent_alias,
    win_school_ncaa                 AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
)

SELECT
  g.season,
  g.`round`,
  g.game_date,
  g.day,
  g.label,
  g.seed,
  g.market,
  g.name,
  g.team_alias AS alias,
  g.school_ncaa,
  g.opponent_seed,
  g.opponent_market,
  g.opponent_name,
  g.opponent_alias,
  g.opponent_school_ncaa
FROM tourney_long AS g
JOIN top5_markets AS t
  ON g.market = t.market
ORDER BY g.market, g.season, g.game_date;