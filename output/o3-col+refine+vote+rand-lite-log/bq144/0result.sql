/* -------------------------------------------------------------
   NCAA M-BB Tournament (2014-on) : team- & opponent-centric view
   -------------------------------------------------------------
   • 2014-2017 results come from mbb_historical_tournament_games
   • 2018 results come from 2018_tournament_results (already split)
   • Pace / efficiency numbers come from feature_engineering
   • Every game appears twice: once from each team’s perspective
   • Added opponent-minus-team deltas for modelling
----------------------------------------------------------------*/
WITH
/*-----------------------------------------------------------------
 1) 2014-2017 tournament games  ➜  “un-pivot” into win / loss rows
-----------------------------------------------------------------*/
hist_wins AS (
  SELECT
    season,
    'win'  AS label,
    win_seed          AS seed,
    win_school_ncaa   AS school_ncaa,
    lose_seed         AS opponent_seed,
    lose_school_ncaa  AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),
hist_losses AS (
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
hist_rows AS (
  SELECT * FROM hist_wins
  UNION ALL
  SELECT * FROM hist_losses
),

/*-----------------------------------------------------------------
 2)  Append 2018 tournament (already tidy = win/loss rows)
-----------------------------------------------------------------*/
all_games AS (
  SELECT * FROM hist_rows
  UNION ALL
  SELECT
    season,
    label,
    seed,
    school_ncaa,
    opponent_seed,
    opponent_school_ncaa
  FROM `data-to-insights.ncaa.2018_tournament_results`
),

/*-----------------------------------------------------------------
 3)  Feature-engineering metrics (pace & efficiency)
-----------------------------------------------------------------*/
fe AS (
  SELECT
    season,
    team                                    AS school_ncaa,
    poss_40min,
    pace_rank,
    pace_rating,
    pts_100poss,
    efficiency_rank,
    efficiency_rating
  FROM `data-to-insights.ncaa.feature_engineering`
),

/*-----------------------------------------------------------------
 4)  Join metrics for team and opponent
-----------------------------------------------------------------*/
joined AS (
  SELECT
    g.*,

    /* team metrics */
    t.poss_40min           AS poss_40min,
    t.pace_rank            AS pace_rank,
    t.pace_rating          AS pace_rating,
    t.pts_100poss          AS pts_100poss,
    t.efficiency_rank      AS efficiency_rank,
    t.efficiency_rating    AS efficiency_rating,

    /* opponent metrics */
    o.poss_40min           AS opp_poss_40min,
    o.pace_rank            AS opp_pace_rank,
    o.pace_rating          AS opp_pace_rating,
    o.pts_100poss          AS opp_pts_100poss,
    o.efficiency_rank      AS opp_efficiency_rank,
    o.efficiency_rating    AS opp_efficiency_rating
  FROM all_games AS g
  LEFT JOIN fe AS t
    ON  t.season       = g.season
    AND t.school_ncaa  = g.school_ncaa
  LEFT JOIN fe AS o
    ON  o.season       = g.season
    AND o.school_ncaa  = g.opponent_school_ncaa
)

/*-----------------------------------------------------------------
 5)  Add opponent-minus-team deltas (useful for modelling)
-----------------------------------------------------------------*/
SELECT
  season,
  label,
  seed,
  school_ncaa,
  opponent_seed,
  opponent_school_ncaa,

  /* team metrics */
  poss_40min,
  pace_rank,
  pace_rating,
  pts_100poss,
  efficiency_rank,
  efficiency_rating,

  /* opponent metrics */
  opp_poss_40min,
  opp_pace_rank,
  opp_pace_rating,
  opp_pts_100poss,
  opp_efficiency_rank,
  opp_efficiency_rating,

  /* deltas:  (opponent – team) */
  opp_pace_rank        - pace_rank         AS pace_rank_diff,
  opp_poss_40min       - poss_40min        AS poss_40min_diff,
  opp_pace_rating      - pace_rating       AS pace_rating_diff,
  opp_efficiency_rank  - efficiency_rank   AS efficiency_rank_diff,
  opp_pts_100poss      - pts_100poss       AS pts_100poss_diff,
  opp_efficiency_rating- efficiency_rating AS efficiency_rating_diff
FROM joined
ORDER BY season, school_ncaa, label;