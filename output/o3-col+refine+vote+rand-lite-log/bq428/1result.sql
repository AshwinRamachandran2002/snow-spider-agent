/* ----------------------------------------------------------------------
   1) Identify every player-game (2010-2018) with ≥15 PTS in the 2nd period
   2) Count distinct players per market that reached that mark
   3) Keep the TOP-5 markets with the highest distinct-player counts
   4) Return every NCAA historical-tournament game (2010-2018) in which
      any of those five markets participated, flagging whether they won
---------------------------------------------------------------------- */
WITH second_period_15 AS (
  SELECT
    team_market,
    player_id
  FROM (
    SELECT
      season,
      game_id,
      team_market,
      player_id,
      SUM(points_scored) AS pts_second_period
    FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
    WHERE season BETWEEN 2010 AND 2018
      AND period = 2
      AND points_scored IS NOT NULL
    GROUP BY season, game_id, team_market, player_id
  )
  WHERE pts_second_period >= 15
),
top_markets AS (
  SELECT
    team_market
  FROM second_period_15
  GROUP BY team_market
  ORDER BY COUNT(DISTINCT player_id) DESC
  LIMIT 5
),
tourney_games AS (
  SELECT
    htg.*,
    /* which of the two schools is one of the TOP-5 markets? */
    CASE
      WHEN htg.win_market IN (SELECT team_market FROM top_markets) THEN htg.win_market
      ELSE htg.lose_market
    END AS team_market,
    /* did that market win or lose this game? */
    CASE
      WHEN htg.win_market IN (SELECT team_market FROM top_markets) THEN 'win'
      ELSE 'loss'
    END AS result
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games` AS htg
  WHERE htg.season BETWEEN 2010 AND 2018
    AND (
         htg.win_market  IN (SELECT team_market FROM top_markets)
      OR htg.lose_market IN (SELECT team_market FROM top_markets)
    )
)

SELECT
  season,
  game_date,
  team_market,       -- one of the TOP-5 markets
  result,            -- 'win' if this market won the game, else 'loss'
  `round`,           -- tournament round (# of teams remaining)
  win_seed,
  win_market,
  win_name,
  win_pts,
  lose_seed,
  lose_market,
  lose_name,
  lose_pts
FROM tourney_games
ORDER BY season, game_date, team_market;