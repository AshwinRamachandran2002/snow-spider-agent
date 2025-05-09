/* -----------------------------------------------------------
   1.  Identify the 5 markets with the most DISTINCT players
       who scored ≥15 pts in the 2nd period (2010-2018).
   2.  Return every NCAA-tournament game (2010-2018) that any
       of those markets played, with the columns described in
       the data-model document and a win/loss label.
   ----------------------------------------------------------- */
WITH big_scoring AS (      -- players with 15+ pts in period-2
  SELECT
    team_market,
    player_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2
    AND shot_made = TRUE
  GROUP BY team_market, player_id
  HAVING SUM(points_scored) >= 15
),

top5 AS (                  -- top-5 markets by # distinct players
  SELECT team_market
  FROM big_scoring
  GROUP BY team_market
  ORDER BY COUNT(DISTINCT player_id) DESC
  LIMIT 5
),

tourney AS (               -- union wins & losses with “label”
  SELECT
    season,
    round,
    game_date,
    day,
    'win' AS label,
    win_seed        AS seed,
    win_market      AS market,
    win_name        AS name,
    win_alias       AS alias,
    win_school_ncaa AS school_ncaa,
    lose_seed       AS opponent_seed,
    lose_market     AS opponent_market,
    lose_name       AS opponent_name,
    lose_alias      AS opponent_alias,
    lose_school_ncaa AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
    AND win_market IN (SELECT team_market FROM top5)

  UNION ALL

  SELECT
    season,
    round,
    game_date,
    day,
    'loss' AS label,
    lose_seed        AS seed,
    lose_market      AS market,
    lose_name        AS name,
    lose_alias       AS alias,
    lose_school_ncaa AS school_ncaa,
    win_seed         AS opponent_seed,
    win_market       AS opponent_market,
    win_name         AS opponent_name,
    win_alias        AS opponent_alias,
    win_school_ncaa  AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
    AND lose_market IN (SELECT team_market FROM top5)
)

SELECT *
FROM   tourney
ORDER  BY market, season, round;