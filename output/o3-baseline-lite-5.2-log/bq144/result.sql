-- ============================================================================
-- NCAA MEN’S TOURNAMENT (2014‑present):
-- Game outcome + pace / efficiency metrics for each team & its opponent.
-- The result‑set can be saved as a new table or used as a sub‑query for
-- additional modelling / visualisation work.
-- ============================================================================

WITH  /* ---------------------------------------------------------------
        1.  Assemble every tournament game (one row per TEAM‑game)
        ----------------------------------------------------------------*/
tournament_games AS (

  /* -------- historical tournament results --------------------------------*/
  SELECT
      season,
      'win'                                           AS label,
      win_seed                                        AS seed,
      win_school_ncaa                                 AS school_ncaa,
      lose_seed                                       AS opponent_seed,
      lose_school_ncaa                                AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  SELECT
      season,
      'loss'                                          AS label,
      lose_seed                                       AS seed,
      lose_school_ncaa                                AS school_ncaa,
      win_seed                                        AS opponent_seed,
      win_school_ncaa                                 AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  /* -------- 2018 results table (already split by win / loss) --------------*/
  UNION ALL
  SELECT
      season,
      label,
      seed,
      school_ncaa,
      opponent_seed,
      opponent_school_ncaa
  FROM  `data-to-insights.ncaa.2018_tournament_results`
  WHERE season >= 2014
),

/* --------------------------------------------------------------------------
   2.  Bring in pace & efficiency numbers for every school / season
   -------------------------------------------------------------------------*/
team_metrics AS (
  SELECT  season,
          team                                            AS school_ncaa,
          poss_40min,
          pace_rating,
          pace_rank,
          pts_100poss,
          efficiency_rating,
          efficiency_rank
  FROM    `data-to-insights.ncaa.feature_engineering`
),

/* --------------------------------------------------------------------------
   3.  Combine games with metrics for team AND opponent
   -------------------------------------------------------------------------*/
games_with_metrics AS (
  SELECT
      g.season,
      g.label,
      g.seed,
      g.school_ncaa,
      g.opponent_seed,
      g.opponent_school_ncaa,

      /* ---------- team metrics ----------------*/
      tm.pace_rank          AS pace_rank,
      tm.poss_40min         AS poss_40min,
      tm.pace_rating        AS pace_rating,
      tm.efficiency_rank    AS efficiency_rank,
      tm.pts_100poss        AS pts_100poss,
      tm.efficiency_rating  AS efficiency_rating,

      /* ---------- opponent metrics ------------*/
      om.pace_rank          AS opp_pace_rank,
      om.poss_40min         AS opp_poss_40min,
      om.pace_rating        AS opp_pace_rating,
      om.efficiency_rank    AS opp_efficiency_rank,
      om.pts_100poss        AS opp_pts_100poss,
      om.efficiency_rating  AS opp_efficiency_rating
  FROM   tournament_games g
  LEFT JOIN team_metrics tm
         ON  tm.season       = g.season
         AND LOWER(tm.school_ncaa) = LOWER(g.school_ncaa)
  LEFT JOIN team_metrics om
         ON  om.season       = g.season
         AND LOWER(om.school_ncaa) = LOWER(g.opponent_school_ncaa)
)

/* --------------------------------------------------------------------------
   4.  Final select ‑‑ add metric DIFFERENCES to aid modelling
   -------------------------------------------------------------------------*/
SELECT
    season,
    label,
    seed,
    school_ncaa,
    opponent_seed,
    opponent_school_ncaa,

    /* -------- team metrics ----------*/
    pace_rank,
    poss_40min,
    pace_rating,
    efficiency_rank,
    pts_100poss,
    efficiency_rating,

    /* -------- opponent metrics ------*/
    opp_pace_rank,
    opp_poss_40min,
    opp_pace_rating,
    opp_efficiency_rank,
    opp_pts_100poss,
    opp_efficiency_rating,

    /* -------- differences (opp – team)*/
    (opp_pace_rank        - pace_rank)         AS pace_rank_diff,
    (opp_poss_40min       - poss_40min)        AS pace_stat_diff,
    (opp_pace_rating      - pace_rating)       AS pace_rating_diff,
    (opp_efficiency_rank  - efficiency_rank)   AS eff_rank_diff,
    (opp_pts_100poss      - pts_100poss)       AS eff_stat_diff,
    (opp_efficiency_rating- efficiency_rating) AS eff_rating_diff

FROM  games_with_metrics
ORDER BY season, school_ncaa, label;