-- 1.  Find the five team markets that have the most DISTINCT players who scored
--    at least 15 points **in the 2nd period** of any game (seasons 2010‑2018).
-- 2.  Return every NCAA‑tournament game (2010‑2018) in which those markets
--     participated – with a win/loss label and other details described in the
--     “historical tournament” data‑model document.

WITH player_second_period_pts AS (
  SELECT
    season,
    game_id,
    team_market                AS market,
    player_id,
    SUM(CAST(points_scored AS INT64)) AS period2_points
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2                              -- 2nd half / 2nd period
    AND points_scored IS NOT NULL
    AND points_scored > 0
    AND team_market IS NOT NULL
    AND player_id   IS NOT NULL
  GROUP BY season, game_id, market, player_id
),
players_with_15 AS (
  SELECT DISTINCT market, player_id
  FROM player_second_period_pts
  WHERE period2_points >= 15                    -- hit the 15‑point threshold
),
market_player_counts AS (
  SELECT
    market,
    COUNT(DISTINCT player_id) AS num_distinct_players
  FROM players_with_15
  GROUP BY market
),
top5_markets AS (
  SELECT market, num_distinct_players
  FROM market_player_counts
  ORDER BY num_distinct_players DESC, market
  LIMIT 5                                        -- TOP‑5 markets
)

SELECT
  t.market                                 AS team_market,
  t.num_distinct_players,                  -- how many qualifying scorers
  g.season,
  g.round,
  g.game_date,
  g.day,
  CASE
      WHEN g.win_market = t.market THEN 'win'
      ELSE 'loss'
  END                                       AS label,
  -- seed & opponent information (mirrors the doc’s combined model fields)
  CASE WHEN g.win_market = t.market THEN g.win_seed  ELSE g.lose_seed END AS seed,
  CASE WHEN g.win_market = t.market THEN g.lose_seed ELSE g.win_seed  END AS opponent_seed,
  CASE WHEN g.win_market = t.market THEN g.lose_market ELSE g.win_market END AS opponent_market,
  CASE WHEN g.win_market = t.market THEN g.lose_name   ELSE g.win_name  END AS opponent_name,
  CASE WHEN g.win_market = t.market THEN g.lose_alias  ELSE g.win_alias END AS opponent_alias,
  -- points
  CASE WHEN g.win_market = t.market THEN g.win_pts  ELSE g.lose_pts END AS team_points,
  CASE WHEN g.win_market = t.market THEN g.lose_pts ELSE g.win_pts  END AS opponent_points,
  g.num_ot
FROM  top5_markets t
JOIN  `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games` g
  ON  g.season BETWEEN 2010 AND 2018
  AND (g.win_market = t.market OR g.lose_market = t.market)
ORDER BY
  t.num_distinct_players DESC,
  team_market,
  g.season,
  g.round;