/* --------------------------------------------------------------
   Combined NCAA men’s tournament dataset (2014‑present) with
   team & opponent pace/efficiency metrics plus differences.
-------------------------------------------------------------- */

WITH tourney_long AS (
  /* 2014‑2017 winners */
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

  /* 2014‑2017 losers */
  SELECT
      season,
      'loss',
      lose_seed,
      lose_school_ncaa,
      win_seed,
      win_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  /* 2018 file (already long format) */
  SELECT
      season,
      label,
      seed,
      school_ncaa,
      opponent_seed,
      opponent_school_ncaa
  FROM `data-to-insights.ncaa.2018_tournament_results`
  WHERE season = 2018
),

metrics_joined AS (
  SELECT
      t.*,

      /* team metrics */
      tm.pace_rank         AS team_pace_rank,
      tm.poss_40min        AS team_poss_40min,
      tm.pace_rating       AS team_pace_rating,
      tm.efficiency_rank   AS team_efficiency_rank,
      tm.pts_100poss       AS team_pts_100poss,
      tm.efficiency_rating AS team_efficiency_rating,

      /* opponent metrics */
      opp.pace_rank         AS opp_pace_rank,
      opp.poss_40min        AS opp_poss_40min,
      opp.pace_rating       AS opp_pace_rating,
      opp.efficiency_rank   AS opp_efficiency_rank,
      opp.pts_100poss       AS opp_pts_100poss,
      opp.efficiency_rating AS opp_efficiency_rating

  FROM tourney_long t
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` tm
         ON tm.season = t.season
        AND LOWER(tm.team) = LOWER(t.school_ncaa)
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` opp
         ON opp.season = t.season
        AND LOWER(opp.team) = LOWER(t.opponent_school_ncaa)
)

SELECT
    season,
    label                                               AS game_result,
    seed                                                AS team_seed,
    opponent_seed,
    school_ncaa                                         AS team_school,
    opponent_school_ncaa                                AS opponent_school,

    /* pace / tempo */
    team_pace_rank      AS team_adj_tempo_rank,
    opp_pace_rank       AS opp_adj_tempo_rank,
    ROUND(team_poss_40min ,4)  AS team_adj_tempo,
    ROUND(opp_poss_40min  ,4)  AS opp_adj_tempo,
    ROUND(opp_poss_40min - team_poss_40min ,4)          AS tempo_diff,

    /* offensive efficiency */
    team_efficiency_rank    AS team_adj_off_rank,
    opp_efficiency_rank     AS opp_adj_off_rank,
    ROUND(team_pts_100poss ,4)  AS team_adj_off,
    ROUND(opp_pts_100poss  ,4)  AS opp_adj_off,
    ROUND(opp_pts_100poss - team_pts_100poss ,4)        AS adj_off_diff,

    /* defensive efficiency (proxy = overall efficiency rating) */
    team_efficiency_rank    AS team_adj_def_rank,
    opp_efficiency_rank     AS opp_adj_def_rank,
    ROUND(team_efficiency_rating ,4) AS team_adj_def,
    ROUND(opp_efficiency_rating  ,4) AS opp_adj_def,
    ROUND(opp_efficiency_rating - team_efficiency_rating ,4) AS adj_def_diff
FROM metrics_joined
ORDER BY season, team_school, game_result;