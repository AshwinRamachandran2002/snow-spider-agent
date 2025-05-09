/* Top-5 markets (2010-2018) with the most DISTINCT players who scored ≥15
   points in period-2 of any game, then list every NCAA-tournament game
   (2010-2018) those markets played, showing win/loss and opponent details   */

WITH period2_15pts AS (           -- one row per player-game that hit 15+ pts in 2nd period
  SELECT
      season,
      team_market,
      player_id
  FROM (
        SELECT
            season,
            game_id,
            team_market,
            player_id,
            SUM(points_scored) AS pts_p2
        FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
        WHERE season BETWEEN 2010 AND 2018          -- PBP available from 2013; earlier years simply absent
          AND period = 2
          AND shot_made = TRUE
        GROUP BY season, game_id, team_market, player_id
       )
  WHERE pts_p2 >= 15
),
top5_markets AS (                 -- pick the five markets with the most such DISTINCT players
  SELECT
      team_market
  FROM (
        SELECT
            team_market,
            COUNT(DISTINCT player_id) AS distinct_players
        FROM period2_15pts
        GROUP BY team_market
        ORDER BY distinct_players DESC
        LIMIT 5
       )
),

tourney_games AS (                -- all tourney games 2010-2018 for those markets
  SELECT
      htg.season,
      htg.round,
      htg.game_date,
      
      /* perspective of the top-5 market */
      CASE 
        WHEN top.team_market = htg.win_market  THEN 'win'
        ELSE                                      'loss'
      END                                       AS label,
      
      /* team (top-5 market) details */
      top.team_market                           AS market,
      IF(top.team_market = htg.win_market,
         htg.win_seed,  htg.lose_seed)          AS seed,
      IF(top.team_market = htg.win_market,
         htg.win_name,  htg.lose_name)          AS name,
      IF(top.team_market = htg.win_market,
         htg.win_alias, htg.lose_alias)         AS alias,
      IF(top.team_market = htg.win_market,
         htg.win_school_ncaa, htg.lose_school_ncaa) AS school_ncaa,
      IF(top.team_market = htg.win_market,
         htg.win_pts,  htg.lose_pts)            AS team_pts,
      
      /* opponent details */
      IF(top.team_market = htg.win_market,
         htg.lose_seed,  htg.win_seed)          AS opponent_seed,
      IF(top.team_market = htg.win_market,
         htg.lose_market, htg.win_market)       AS opponent_market,
      IF(top.team_market = htg.win_market,
         htg.lose_name,  htg.win_name)          AS opponent_name,
      IF(top.team_market = htg.win_market,
         htg.lose_alias, htg.win_alias)         AS opponent_alias,
      IF(top.team_market = htg.win_market,
         htg.lose_school_ncaa, htg.win_school_ncaa) AS opponent_school_ncaa,
      IF(top.team_market = htg.win_market,
         htg.lose_pts,  htg.win_pts)            AS opponent_pts
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games` htg
  JOIN top5_markets top
    ON top.team_market IN (htg.win_market, htg.lose_market)
  WHERE htg.season BETWEEN 2010 AND 2018
)

SELECT *
FROM tourney_games
ORDER BY market, season, round;