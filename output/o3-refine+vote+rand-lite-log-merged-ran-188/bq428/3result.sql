-- 1) Identify the five team markets that had the most distinct players
--    scoring 15 + points in Period 2 of any game (2010-2018 seasons).
-- 2) Return every NCAA tournament game (2010-2018) in which ANY of those
--    markets participated, labelling whether the market won or lost and
--    giving basic score details.

WITH top5 AS (
  /* -------------------------------------------------------------
     Count distinct players who scored ≥15 PTS in the 2nd period
     of a game during seasons 2010-2018, then keep the top-5 markets
  -------------------------------------------------------------- */
  SELECT
      team_market,
      COUNT(DISTINCT player_id) AS n_players_15pts_p2
  FROM (
        SELECT
            game_id,
            team_market,
            player_id,
            SUM(points_scored) AS period2_pts
        FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
        WHERE season BETWEEN 2010 AND 2018
          AND period = 2
          AND shot_made = TRUE
          AND points_scored IS NOT NULL
        GROUP BY game_id, team_market, player_id
        HAVING period2_pts >= 15     -- player hit 15+ PTS in P2
  )
  GROUP BY team_market
  ORDER BY n_players_15pts_p2 DESC
  LIMIT 5
),
tourney AS (
  /* -------------------------------------------------------------
     Pull historical tournament games for the same time frame
  -------------------------------------------------------------- */
  SELECT *
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
)

SELECT
    t.season,
    t.round,
    t.game_date,
    -- market of interest (one of the TOP-5)
    CASE
        WHEN t.win_market IN (SELECT team_market FROM top5) THEN t.win_market
        ELSE t.lose_market
    END                                                   AS team_market,
    -- opponent market
    CASE
        WHEN t.win_market IN (SELECT team_market FROM top5) THEN t.lose_market
        ELSE t.win_market
    END                                                   AS opponent_market,
    -- result for the TOP-5 market
    CASE
        WHEN t.win_market IN (SELECT team_market FROM top5) THEN 'W'
        ELSE 'L'
    END                                                   AS result,
    ABS(t.win_pts - t.lose_pts)                           AS score_diff,
    t.win_pts,
    t.lose_pts
FROM tourney AS t
WHERE t.win_market IN (SELECT team_market FROM top5)
   OR t.lose_market IN (SELECT team_market FROM top5)
ORDER BY team_market, t.season, t.round;