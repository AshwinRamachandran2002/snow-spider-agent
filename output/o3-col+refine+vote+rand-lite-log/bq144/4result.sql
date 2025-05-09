/* ============================================================================
   NCAA MEN’S TOURNAMENT – TEAM-vs-OPPONENT METRIC DATASET  (2014-present)
   ----------------------------------------------------------------------------
   • Combines historical tournament games (2014-2017, 2019+) with the dedicated
     2018 results table.
   • Adds pace & efficiency metrics for each team and its opponent.
   • Provides metric DIFFERENCES (team minus opponent).
   ============================================================================ */

WITH ---------------------------------------------------------------------------
/* 1.  Historical games reshaped into win/loss rows -------------------------- */
hist AS (
  SELECT
      season,
      'win'                       AS label,
      win_seed                    AS seed,
      win_school_ncaa             AS school_ncaa,
      lose_seed                   AS opponent_seed,
      lose_school_ncaa            AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  SELECT
      season,
      'loss'                      AS label,
      lose_seed,
      lose_school_ncaa,
      win_seed,
      win_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),

/* 2.  Append the 2018 tournament results (same column order) ---------------- */
base AS (
  SELECT * FROM hist

  UNION ALL

  SELECT
      season,
      label,
      seed,
      school_ncaa,
      opponent_seed,
      opponent_school_ncaa
  FROM  `data-to-insights.ncaa.2018_tournament_results`
),

/* 3.  Attach pace/efficiency metrics for team and opponent ------------------ */
metrics AS (
  SELECT
      b.*,

      /* team metrics */
      t.poss_40min            AS poss_40min,
      t.pace_rank             AS pace_rank,
      t.pace_rating           AS pace_rating,
      t.pts_100poss           AS pts_100poss,
      t.efficiency_rank       AS efficiency_rank,
      t.efficiency_rating     AS efficiency_rating,

      /* opponent metrics */
      o.poss_40min            AS opp_poss_40min,
      o.pace_rank             AS opp_pace_rank,
      o.pace_rating           AS opp_pace_rating,
      o.pts_100poss           AS opp_pts_100poss,
      o.efficiency_rank       AS opp_efficiency_rank,
      o.efficiency_rating     AS opp_efficiency_rating
  FROM base AS b
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS t
         ON t.season = b.season
        AND t.team   = b.school_ncaa
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS o
         ON o.season = b.season
        AND o.team   = b.opponent_school_ncaa
)

-- 4.  Final select with metric DIFFERENCES -----------------------------------
SELECT
    season,
    label,
    seed,
    school_ncaa,
    opponent_seed,
    opponent_school_ncaa,

    /* ------------- team metrics ------------- */
    pace_rank,
    poss_40min,
    pace_rating,
    pts_100poss,
    efficiency_rank,
    efficiency_rating,

    /* ----------- opponent metrics ----------- */
    opp_pace_rank,
    opp_poss_40min,
    opp_pace_rating,
    opp_pts_100poss,
    opp_efficiency_rank,
    opp_efficiency_rating,

    /* -------- differences (team – opponent) -------- */
    pace_rank        - opp_pace_rank        AS pace_rank_diff,
    poss_40min       - opp_poss_40min       AS poss_40min_diff,
    pace_rating      - opp_pace_rating      AS pace_rating_diff,
    efficiency_rank  - opp_efficiency_rank  AS eff_rank_diff,
    pts_100poss      - opp_pts_100poss      AS pts_100poss_diff,
    efficiency_rating- opp_efficiency_rating AS eff_rating_diff

FROM  metrics
ORDER BY season, school_ncaa, opponent_school_ncaa;