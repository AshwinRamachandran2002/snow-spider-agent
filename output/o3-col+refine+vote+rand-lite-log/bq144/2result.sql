-- Create one tidy table of NCAA-men’s tournament games (2014-current)
-- enriched with each team’s & opponent’s pace / efficiency metrics
-- plus simple opponent-minus-team “diff” features.

WITH hist AS (   -- ❶ Historical tourney (through 2017)
  SELECT
    season,
    'win'  AS label,
    win_seed        AS seed,
    win_school_ncaa AS school_ncaa,
    lose_seed       AS opponent_seed,
    lose_school_ncaa AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  SELECT
    season,
    'loss' AS label,
    lose_seed,
    lose_school_ncaa,
    win_seed,
    win_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),

yr2018 AS (      -- ❷ Stand-alone 2018 results file (already has win/loss rows)
  SELECT
    season,
    label,
    seed,
    school_ncaa,
    opponent_seed,
    opponent_school_ncaa
  FROM `data-to-insights.ncaa.2018_tournament_results`
),

all_games AS (   -- ❸ Stack them together
  SELECT * FROM hist
  UNION ALL
  SELECT * FROM yr2018
)

-- ❹ Join in pace / efficiency numbers for both team & opponent
SELECT
  g.season,
  g.label,
  g.seed,
  g.school_ncaa,
  g.opponent_seed,
  g.opponent_school_ncaa,

  -- team metrics
  t.pace_rank,
  t.poss_40min,
  t.pace_rating,
  t.efficiency_rank,
  t.pts_100poss,
  t.efficiency_rating,

  -- opponent metrics
  o.pace_rank             AS opp_pace_rank,
  o.poss_40min            AS opp_poss_40min,
  o.pace_rating           AS opp_pace_rating,
  o.efficiency_rank       AS opp_efficiency_rank,
  o.pts_100poss           AS opp_pts_100poss,
  o.efficiency_rating     AS opp_efficiency_rating,

  -- simple opponent-minus-team feature deltas
  (o.pace_rank         - t.pace_rank)         AS pace_rank_diff,
  (o.poss_40min        - t.poss_40min)        AS poss_40min_diff,
  (o.pace_rating       - t.pace_rating)       AS pace_rating_diff,
  (o.efficiency_rank   - t.efficiency_rank)   AS eff_rank_diff,
  (o.pts_100poss       - t.pts_100poss)       AS pts_100poss_diff,
  (o.efficiency_rating - t.efficiency_rating) AS eff_rating_diff
FROM   all_games AS g
LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS t
       ON t.season = g.season
      AND t.team   = g.school_ncaa
LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS o
       ON o.season = g.season
      AND o.team   = g.opponent_school_ncaa
ORDER BY g.season, g.label, g.school_ncaa;