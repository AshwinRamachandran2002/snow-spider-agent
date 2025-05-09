-- chronological list of every scoring play in the 2014 season game
-- with the Wildcats at home and the Fighting Irish away
WITH chosen_game AS (
  SELECT DISTINCT game_id,
                  home_market      AS wildcats_market,
                  away_market      AS irish_market
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season = 2014
    AND home_name = 'Wildcats'
    AND away_name = 'Fighting Irish'
),

scoring_events AS (
  SELECT
    p.game_id,
    p.elapsed_time_sec,
    p.game_clock,
    p.points_scored,
    p.event_description,
    CASE
      WHEN p.team_market = cg.wildcats_market THEN 'Wildcats'
      WHEN p.team_market = cg.irish_market    THEN 'Fighting Irish'
    END                                              AS scoring_team,
    -- keep team_market for cumulative‑score logic
    p.team_market,
    cg.wildcats_market,
    cg.irish_market
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` p
  JOIN chosen_game cg
    ON p.game_id = cg.game_id
  WHERE p.points_scored IS NOT NULL
    AND p.points_scored > 0          -- only scoring plays
)

SELECT
  game_clock,
  SUM(CASE WHEN team_market = wildcats_market THEN points_scored ELSE 0 END)
      OVER (PARTITION BY game_id ORDER BY elapsed_time_sec
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS wildcats_cum_pts,
  SUM(CASE WHEN team_market = irish_market THEN points_scored ELSE 0 END)
      OVER (PARTITION BY game_id ORDER BY elapsed_time_sec
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS fightingirish_cum_pts,
  scoring_team,
  event_description
FROM scoring_events
ORDER BY elapsed_time_sec;