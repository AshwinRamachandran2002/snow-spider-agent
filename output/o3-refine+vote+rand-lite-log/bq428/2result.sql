-- 1) Find the five team‑markets that have the most DISTINCT players
--    who scored at least 15 points **in the 2nd period of any game**
--    between the 2010 and 2018 seasons (inclusive).
-- 2) Return every NCAA‑tournament game (2010‑2018) in which any of
--    those markets appeared – whether they won or lost.

WITH player_period2_pts AS (      -- points a player scored in period 2 of ONE game
  SELECT
    game_id,
    player_id,
    ANY_VALUE(player_full_name)  AS player_name,
    ANY_VALUE(team_market)       AS market,
    SUM(points_scored)           AS pts_p2
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2                  -- second half / period
    AND shot_made = TRUE            -- only made shots
    AND points_scored IS NOT NULL
  GROUP BY game_id, player_id
),
qualified_players AS (            -- player hit the 15‑point threshold in period 2
  SELECT DISTINCT
    player_id,
    market
  FROM player_period2_pts
  WHERE pts_p2 >= 15
),
top5_markets AS (                 -- top‑5 markets by number of such players
  SELECT
    market,
    COUNT(DISTINCT player_id) AS player_cnt
  FROM qualified_players
  GROUP BY market
  ORDER BY player_cnt DESC
  LIMIT 5
),
tourney_games AS (                -- all tourney games 2010‑2018 for those markets
  SELECT *
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
    AND (
          win_market  IN (SELECT market FROM top5_markets)
       OR lose_market IN (SELECT market FROM top5_markets)
        )
)

SELECT *
FROM tourney_games
ORDER BY season, game_date;