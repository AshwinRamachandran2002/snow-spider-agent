/*  -----------------------------------------------------------
    1)  Find every (game, player) that scored ≥15 points in the
        2nd period between 2010-2018.
    2)  Keep the five team-markets that have the most DISTINCT
        such scorers.
    3)  Reshape the historical-tournament table so each row
        represents ONE team (label = 'win' / 'loss'), following
        the data-model specification (seed, opponent_seed, …).
    4)  Return every tournament game-row whose market is in the
        TOP-5 set, seasons 2010-2018.
    ----------------------------------------------------------- */
WITH period2_scorers AS (
  SELECT
    team_market,
    player_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2
  GROUP BY team_market, player_id, game_id
  HAVING SUM(CAST(points_scored AS INT64)) >= 15
),
top_markets AS (
  SELECT
    team_market
  FROM period2_scorers
  GROUP BY team_market
  ORDER BY COUNT(DISTINCT player_id) DESC
  LIMIT 5
),
tournament_games AS (
  /*  Winner rows  */
  SELECT
    season,
    round,
    days_from_epoch,
    game_date,
    day,
    'win'            AS label,
    win_seed         AS seed,
    win_market       AS market,
    win_name         AS name,
    win_alias        AS alias,
    win_school_ncaa  AS school_ncaa,
    lose_seed        AS opponent_seed,
    lose_market      AS opponent_market,
    lose_name        AS opponent_name,
    lose_alias       AS opponent_alias,
    lose_school_ncaa AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018

  UNION ALL

  /*  Loser rows  */
  SELECT
    season,
    round,
    days_from_epoch,
    game_date,
    day,
    'loss'           AS label,
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
)
SELECT
  season,
  round,
  game_date,
  day,
  label,
  seed,
  market,
  name,
  alias,
  school_ncaa,
  opponent_seed,
  opponent_market,
  opponent_name,
  opponent_alias,
  opponent_school_ncaa
FROM tournament_games
WHERE market IN (SELECT team_market FROM top_markets)
ORDER BY market, season, round, game_date;