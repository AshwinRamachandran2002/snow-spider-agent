WITH players_scoring AS (
    -- Players who scored ≥15 pts in the 2nd period, 2010‑2018
    SELECT
        team_market,
        player_id,
        SUM(points_scored) AS pts_2nd_period
    FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
    WHERE season BETWEEN 2010 AND 2018
      AND period = 2                     -- 2nd half
      AND points_scored IS NOT NULL
      AND team_market IS NOT NULL
    GROUP BY team_market, player_id
    HAVING pts_2nd_period >= 15
),
top_markets AS (
    -- Top‑5 markets by distinct qualifying players
    SELECT
        team_market AS market,
        COUNT(DISTINCT player_id) AS num_players
    FROM players_scoring
    GROUP BY team_market
    ORDER BY num_players DESC
    LIMIT 5
)
-- Tournament game details for those markets, 2010‑2018
SELECT
    g.*
FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games` AS g
JOIN top_markets tm
  ON g.win_market = tm.market
  OR g.lose_market = tm.market
WHERE g.season BETWEEN 2010 AND 2018
ORDER BY g.season, g.game_date, g.round, g.win_market, g.lose_market;