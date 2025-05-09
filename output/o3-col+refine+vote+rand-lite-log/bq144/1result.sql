/* -----------------------------------------------------------
   NCAA Men’s Tournament outcomes (2014-on) enriched with
   pace & efficiency metrics for both teams and opponents,
   plus metric differentials.
   ----------------------------------------------------------- */
WITH hist_tourney AS (
  -- Put each historical game (2014+) in a “one row per team” shape
  SELECT
    season,
    'win' AS label,
    win_seed            AS seed,
    win_school_ncaa     AS school_ncaa,
    lose_seed           AS opponent_seed,
    lose_school_ncaa    AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
  
  UNION ALL
  
  SELECT
    season,
    'loss' AS label,
    lose_seed           AS seed,
    lose_school_ncaa    AS school_ncaa,
    win_seed            AS opponent_seed,
    win_school_ncaa     AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),
tourney_2018 AS (
  -- 2018 data already in the desired shape
  SELECT
    season,
    label,
    seed,
    school_ncaa,
    opponent_seed,
    opponent_school_ncaa
  FROM `data-to-insights.ncaa.2018_tournament_results`
),
all_tourney AS (
  -- Combine historical (2014-2017, 2019-…) with 2018 table
  SELECT * FROM hist_tourney
  UNION ALL
  SELECT * FROM tourney_2018
),
joined AS (
  -- Attach pace / efficiency metrics for the team and the opponent
  SELECT
    t.*,
    fe.pace_rank,
    fe.poss_40min,
    fe.pace_rating,
    fe.efficiency_rank,
    fe.pts_100poss,
    fe.efficiency_rating,
    
    opp_fe.pace_rank         AS opp_pace_rank,
    opp_fe.poss_40min        AS opp_poss_40min,
    opp_fe.pace_rating       AS opp_pace_rating,
    opp_fe.efficiency_rank   AS opp_efficiency_rank,
    opp_fe.pts_100poss       AS opp_pts_100poss,
    opp_fe.efficiency_rating AS opp_efficiency_rating
  FROM all_tourney t
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` fe
    ON  fe.season = t.season
    AND fe.team   = t.school_ncaa
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` opp_fe
    ON  opp_fe.season = t.season
    AND opp_fe.team   = t.opponent_school_ncaa
)
SELECT
  season,
  label,                       -- win / loss
  seed,
  school_ncaa,
  opponent_seed,
  opponent_school_ncaa,
  
  /* ---- team metrics ---- */
  pace_rank,
  poss_40min,
  pace_rating,
  efficiency_rank,
  pts_100poss,
  efficiency_rating,
  
  /* ---- opponent metrics ---- */
  opp_pace_rank,
  opp_poss_40min,
  opp_pace_rating,
  opp_efficiency_rank,
  opp_pts_100poss,
  opp_efficiency_rating,
  
  /* ---- differentials (opponent − team) ---- */
  (opp_pace_rank        - pace_rank)        AS pace_rank_diff,
  (opp_poss_40min       - poss_40min)       AS poss_40min_diff,
  (opp_pace_rating      - pace_rating)      AS pace_rating_diff,
  (opp_efficiency_rank  - efficiency_rank)  AS eff_rank_diff,
  (opp_pts_100poss      - pts_100poss)      AS pts_100poss_diff,
  (opp_efficiency_rating- efficiency_rating)AS eff_rating_diff
FROM joined
ORDER BY season, school_ncaa, label;