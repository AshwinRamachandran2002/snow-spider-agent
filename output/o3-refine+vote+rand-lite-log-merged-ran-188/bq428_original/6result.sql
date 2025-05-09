-- Top‑5 markets by number of distinct players who scored ≥15 points 
-- in the 2nd period of any game (2010‑2018), then list every NCAA
-- tournament game (2010‑2018) those markets played in, using the
-- column layout described in the data‑model document.
WITH period2_player_points AS (
  SELECT
    player_id,
    team_market                         AS market,
    SUM(IFNULL(points_scored,0))        AS total_points
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018
    AND period = 2                      -- second half
    AND shot_made = TRUE                -- only made shots count
  GROUP BY player_id, market
  HAVING total_points >= 15             -- player hit 15+ in that period
),

top_markets AS (                       -- keep just the 5 best markets
  SELECT
    market,
    COUNT(DISTINCT player_id) AS num_distinct_players
  FROM period2_player_points
  GROUP BY market
  ORDER BY num_distinct_players DESC
  LIMIT 5
),

-- Reshape tournament data so each row is “one team in one game”
tournament_games AS (
  -- winner rows
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
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018

  UNION ALL

  -- loser rows
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
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
),

-- keep only games involving the selected markets
selected_tournament_games AS (
  SELECT tg.*
  FROM tournament_games tg
  JOIN top_markets tm
    ON tg.market = tm.market
)

SELECT *
FROM selected_tournament_games
ORDER BY market,
         season,
         round,
         game_date;