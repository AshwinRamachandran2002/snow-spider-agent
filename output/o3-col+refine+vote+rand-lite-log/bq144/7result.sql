/* ============================================================================
   NCAA MBB Tournament Results (2014-onward) enriched with pace & efficiency
   metrics for both the team and its opponent, plus “opponent – team” diffs
   ============================================================================ */

WITH
/* 1.  Long-form tournament outcomes for every TEAM in each game --------------*/
hist_tourney AS (   -- 2014-present historical tourney games
  SELECT  season,
          'win'  AS label,
          win_seed        AS seed,
          win_school_ncaa AS school_ncaa,
          lose_seed       AS opponent_seed,
          lose_school_ncaa AS opponent_school_ncaa
  FROM    `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE   season >= 2014

  UNION ALL
  SELECT  season,
          'loss',
          lose_seed,
          lose_school_ncaa,
          win_seed,
          win_school_ncaa
  FROM    `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE   season >= 2014
),

tour_2018 AS (      -- dedicated 2018 tournament results table
  SELECT  season,
          label,
          seed,
          school_ncaa,
          opponent_seed,
          opponent_school_ncaa
  FROM    `data-to-insights.ncaa.2018_tournament_results`
),

tourney AS (        -- combine the two sources
  SELECT * FROM hist_tourney
  UNION ALL
  SELECT * FROM tour_2018
),

/* 2.  Attach pace & efficiency metrics for TEAM and OPPONENT -----------------*/
enriched AS (
  SELECT
      t.*,

      /* team metrics */
      tm.pace_rank          AS pace_rank,
      tm.poss_40min         AS poss_40min,
      tm.pace_rating        AS pace_rating,
      tm.efficiency_rank    AS efficiency_rank,
      tm.pts_100poss        AS pts_100poss,
      tm.efficiency_rating  AS efficiency_rating,

      /* opponent metrics */
      op.pace_rank          AS opp_pace_rank,
      op.poss_40min         AS opp_poss_40min,
      op.pace_rating        AS opp_pace_rating,
      op.efficiency_rank    AS opp_efficiency_rank,
      op.pts_100poss        AS opp_pts_100poss,
      op.efficiency_rating  AS opp_efficiency_rating
  FROM   tourney t
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` tm
         ON tm.season = t.season
        AND tm.team   = t.school_ncaa
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` op
         ON op.season = t.season
        AND op.team   = t.opponent_school_ncaa
)

/* 3.  Final select with opponent-minus-team DIFFERENCE columns ---------------*/
SELECT
    season,
    label,
    seed,
    school_ncaa,
    opponent_seed,
    opponent_school_ncaa,

    /* team metrics */
    pace_rank,
    poss_40min,
    pace_rating,
    efficiency_rank,
    pts_100poss,
    efficiency_rating,

    /* opponent metrics */
    opp_pace_rank,
    opp_poss_40min,
    opp_pace_rating,
    opp_efficiency_rank,
    opp_pts_100poss,
    opp_efficiency_rating,

    /* opponent – team differences */
    (opp_pace_rank       - pace_rank)        AS pace_rank_diff,
    (opp_poss_40min      - poss_40min)       AS poss_40min_diff,
    (opp_pace_rating     - pace_rating)      AS pace_rating_diff,
    (opp_efficiency_rank - efficiency_rank)  AS eff_rank_diff,
    (opp_pts_100poss     - pts_100poss)      AS pts_100poss_diff,
    (opp_efficiency_rating - efficiency_rating) AS eff_rating_diff
FROM   enriched
ORDER BY season, school_ncaa, label;