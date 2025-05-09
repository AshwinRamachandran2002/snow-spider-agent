WITH player_second_period_pts AS (
  -- 1.  Points scored by every player in PERIOD 2 (2010‑2018)
  SELECT
    team_market AS market,
    player_id,
    SUM(IFNULL(points_scored,0)) AS pts_second_period
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season BETWEEN 2010 AND 2018           -- academic seasons 2010‑2018
    AND period = 2                             -- second period only
    AND player_id IS NOT NULL
    AND team_market IS NOT NULL
  GROUP BY market, player_id
  HAVING pts_second_period >= 15               -- at least 15 pts in period 2
),
top_markets AS (
  -- 2.  Top‑5 markets by number of DISTINCT players meeting the criterion
  SELECT
    market,
    COUNT(DISTINCT player_id) AS num_players
  FROM player_second_period_pts
  GROUP BY market
  ORDER BY num_players DESC, market
  LIMIT 5
),
tournament_long AS (
  -- 3.  Turn the historical tournament table into a long (win/loss) format
  --     restricted to 2010‑2018 seasons
  -- 3a.  Winners’ rows
  SELECT
    season,
    round,
    days_from_epoch,
    game_date,
    day,
    'win'  AS label,
    win_seed            AS seed,
    win_market          AS market,
    win_name            AS name,
    win_alias           AS alias,
    win_school_ncaa     AS school_ncaa,
    lose_seed           AS opponent_seed,
    lose_market         AS opponent_market,
    lose_name           AS opponent_name,
    lose_alias          AS opponent_alias,
    lose_school_ncaa    AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018

  UNION ALL

  -- 3b.  Losers’ rows
  SELECT
    season,
    round,
    days_from_epoch,
    game_date,
    day,
    'loss' AS label,
    lose_seed           AS seed,
    lose_market         AS market,
    lose_name           AS name,
    lose_alias          AS alias,
    lose_school_ncaa    AS school_ncaa,
    win_seed            AS opponent_seed,
    win_market          AS opponent_market,
    win_name            AS opponent_name,
    win_alias           AS opponent_alias,
    win_school_ncaa     AS opponent_school_ncaa
  FROM `bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games`
  WHERE season BETWEEN 2010 AND 2018
)
-- 4.  Final result: every tournament game (2010‑2018) played by
--     the five markets identified above
SELECT
  tl.season,
  tl.round,
  tl.days_from_epoch,
  tl.game_date,
  tl.day,
  tl.label,
  tl.seed,
  tl.market,
  tl.name,
  tl.alias,
  tl.school_ncaa,
  tl.opponent_seed,
  tl.opponent_market,
  tl.opponent_name,
  tl.opponent_alias,
  tl.opponent_school_ncaa
FROM tournament_long AS tl
JOIN top_markets     AS tm
  ON tl.market = tm.market
ORDER BY
  tl.market,
  tl.season,
  tl.game_date,
  tl.label;