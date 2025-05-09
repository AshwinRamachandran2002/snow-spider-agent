/*  Tournament outcomes 2014‑2018 enriched with pace & efficiency metrics
    – one row per team per game  */

WITH base AS (      -- 1️⃣ outcome (win/loss) & opponent info
  /* historical tournament games 2014‑2017 */
  SELECT
      season,
      'win'                          AS label,
      win_seed                       AS seed,
      win_school_ncaa                AS school_ncaa,
      lose_seed                      AS opponent_seed,
      lose_school_ncaa               AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season BETWEEN 2014 AND 2017

  UNION ALL
  SELECT
      season,
      'loss',
      lose_seed,
      lose_school_ncaa,
      win_seed,
      win_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season BETWEEN 2014 AND 2017

  UNION ALL
  /* Kaggle 2018 tournament results (already double‑sided) */
  SELECT
      season,
      label,
      seed,
      school_ncaa,
      opponent_seed,
      opponent_school_ncaa
  FROM  `data-to-insights.ncaa.2018_tournament_results`
)

SELECT
    b.season,
    b.label,
    b.seed,
    b.school_ncaa,
    b.opponent_seed,
    b.opponent_school_ncaa,

    /*  Team pace / efficiency  */
    t.poss_40min            AS poss_40min,
    t.pace_rating           AS pace_rating,
    t.pace_rank             AS pace_rank,
    t.pts_100poss           AS pts_100poss,
    t.efficiency_rating     AS efficiency_rating,
    t.efficiency_rank       AS efficiency_rank,

    /*  Opponent pace / efficiency  */
    o.poss_40min            AS opp_poss_40min,
    o.pace_rating           AS opp_pace_rating,
    o.pace_rank             AS opp_pace_rank,
    o.pts_100poss           AS opp_pts_100poss,
    o.efficiency_rating     AS opp_efficiency_rating,
    o.efficiency_rank       AS opp_efficiency_rank,

    /*  Differences (opponent – team)  */
    o.pace_rank           - t.pace_rank           AS pace_rank_diff,
    o.poss_40min          - t.poss_40min          AS poss_40min_diff,
    o.pace_rating         - t.pace_rating         AS pace_rating_diff,
    o.efficiency_rank     - t.efficiency_rank     AS eff_rank_diff,
    o.pts_100poss         - t.pts_100poss         AS pts_100poss_diff,
    o.efficiency_rating   - t.efficiency_rating   AS eff_rating_diff

FROM   base b
JOIN   `data-to-insights.ncaa.feature_engineering` t   -- team metrics
       ON  t.season = b.season
       AND t.team   = b.school_ncaa
JOIN   `data-to-insights.ncaa.feature_engineering` o   -- opponent metrics
       ON  o.season = b.season
       AND o.team   = b.opponent_school_ncaa
ORDER BY b.season, b.label DESC, b.school_ncaa;