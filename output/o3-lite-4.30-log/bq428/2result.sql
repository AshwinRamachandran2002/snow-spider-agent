WITH per_game AS (                           -- players with ≥15 PTS in period‑2
  SELECT
    team_market,
    player_id,
    game_id,
    SUM(COALESCE(points_scored,0)) AS p2_pts
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2
  GROUP BY team_market, player_id, game_id
  HAVING p2_pts >= 15
),
player_list AS (                             -- distinct (team, player)
  SELECT DISTINCT team_market, player_id
  FROM per_game
  WHERE team_market IS NOT NULL
    AND team_market <> ''
),
top5_markets AS (                            -- TOP‑5 markets
  SELECT team_market
  FROM (
    SELECT
      team_market,
      COUNT(DISTINCT player_id) AS n_players
    FROM player_list
    GROUP BY team_market
  )
  ORDER BY n_players DESC, team_market
  LIMIT 5
),
tourney_games AS (                           -- 2010‑2018 tournament games
  SELECT *
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
    AND (win_market IN (SELECT team_market FROM top5_markets) OR
         lose_market IN (SELECT team_market FROM top5_markets))
)
SELECT
  season,
  round,
  game_date,
  day,
  'win'                        AS label,
  win_seed                     AS seed,
  win_market                   AS market,
  win_name                     AS name,
  win_alias                    AS alias,
  win_school_ncaa              AS school_ncaa,
  lose_seed                    AS opponent_seed,
  lose_market                  AS opponent_market,
  lose_name                    AS opponent_name,
  lose_alias                   AS opponent_alias,
  lose_school_ncaa             AS opponent_school_ncaa
FROM tourney_games
WHERE win_market IN (SELECT team_market FROM top5_markets)

UNION ALL

SELECT
  season,
  round,
  game_date,
  day,
  'loss'                       AS label,
  lose_seed                    AS seed,
  lose_market                  AS market,
  lose_name                    AS name,
  lose_alias                   AS alias,
  lose_school_ncaa             AS school_ncaa,
  win_seed                     AS opponent_seed,
  win_market                   AS opponent_market,
  win_name                     AS opponent_name,
  win_alias                    AS opponent_alias,
  win_school_ncaa              AS opponent_school_ncaa
FROM tourney_games
WHERE lose_market IN (SELECT team_market FROM top5_markets)

ORDER BY
  season,
  game_date,
  round,
  market,
  label;