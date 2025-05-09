/* ----------------------------------------------------------------------
   NCAA MBB – Tournament outcomes (2014‑present) enriched with
   pace & efficiency metrics for both the team and its opponent.
   The result is one row per team‑game.
   ------------------------------------------------------------------- */
WITH -------------------------------------------------------------------
-- 1.  Historical tournament games (two rows per game: winner & loser)
hist_games AS (
  SELECT
      season,
      'win'                       AS label,
      CAST(REGEXP_EXTRACT(win_seed , r'\d+') AS INT64)  AS seed,
      win_school_ncaa             AS school_ncaa,
      CAST(REGEXP_EXTRACT(lose_seed, r'\d+') AS INT64)  AS opponent_seed,
      lose_school_ncaa            AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  SELECT
      season,
      'loss'                      AS label,
      CAST(REGEXP_EXTRACT(lose_seed, r'\d+') AS INT64)  AS seed,
      lose_school_ncaa            AS school_ncaa,
      CAST(REGEXP_EXTRACT(win_seed , r'\d+') AS INT64)  AS opponent_seed,
      win_school_ncaa             AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),
-- 2.  2018 tournament results (already one row per team‑game)
res_2018 AS (
  SELECT
      season,
      label,
      CAST(REGEXP_EXTRACT(seed          , r'\d+') AS INT64) AS seed,
      school_ncaa,
      CAST(REGEXP_EXTRACT(opponent_seed , r'\d+') AS INT64) AS opponent_seed,
      opponent_school_ncaa
  FROM  `data-to-insights.ncaa.2018_tournament_results`
),
-- 3.  Union of all tournament rows from 2014 season forward
tourney AS (
  SELECT * FROM hist_games
  UNION ALL
  SELECT * FROM res_2018
),
-- 4.  Pace & efficiency metrics (one row per team‑season)
fe AS (
  SELECT
      season,
      team                                          AS school_ncaa,
      poss_40min,
      pace_rating,
      pace_rank,
      pts_100poss,
      efficiency_rating,
      efficiency_rank
  FROM  `data-to-insights.ncaa.feature_engineering`
),
-- 5. Combine tournament outcomes with metrics for team & opponent
joined AS (
  SELECT
      g.season,
      g.label,
      g.seed,
      g.school_ncaa,
      g.opponent_seed,
      g.opponent_school_ncaa,

      /* ---------- team metrics ---------- */
      t.pace_rank            AS pace_rank,
      t.poss_40min           AS poss_40min,
      t.pace_rating          AS pace_rating,
      t.efficiency_rank      AS efficiency_rank,
      t.pts_100poss          AS pts_100poss,
      t.efficiency_rating    AS efficiency_rating,

      /* ---------- opponent metrics ---------- */
      o.pace_rank            AS opp_pace_rank,
      o.poss_40min           AS opp_poss_40min,
      o.pace_rating          AS opp_pace_rating,
      o.efficiency_rank      AS opp_efficiency_rank,
      o.pts_100poss          AS opp_pts_100poss,
      o.efficiency_rating    AS opp_efficiency_rating
  FROM  tourney g
  LEFT JOIN fe  t
         ON  t.season       = g.season
         AND t.school_ncaa  = g.school_ncaa
  LEFT JOIN fe  o
         ON  o.season       = g.season
         AND o.school_ncaa  = g.opponent_school_ncaa
),
-- 6.  Add metric DIFFERENCES (opponent minus team)
final AS (
  SELECT
      *,
      (opp_pace_rank        - pace_rank       )  AS pace_rank_diff,
      (opp_poss_40min       - poss_40min      )  AS poss_40min_diff,
      (opp_pace_rating      - pace_rating     )  AS pace_rating_diff,
      (opp_efficiency_rank  - efficiency_rank )  AS eff_rank_diff,
      (opp_pts_100poss      - pts_100poss     )  AS pts_100poss_diff,
      (opp_efficiency_rating- efficiency_rating) AS eff_rating_diff
  FROM joined
)
-- 7.  Output
SELECT *
FROM   final
ORDER BY season, school_ncaa, label DESC;