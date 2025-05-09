/*--------------------------------------------------------------------
  Create a complete tournament + metrics data-set (2014-present)

  •   Results come from
        ‑ NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES  (2014-2017)
        ‑ NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS          (2018)

  •   Pace / Efficiency metrics (team & opponent) come from
        ‑ NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING

  •   Output includes raw metrics and opponent metrics plus the
      opponent – team differences for quick modelling / exploration.
--------------------------------------------------------------------*/
WITH historical_games AS (          -- 2014-2017, split into win / loss rows
    /* winners */
    SELECT  "season",
            'win'                          AS "label",
            "win_seed"                    AS "seed",
            "win_school_ncaa"             AS "school_ncaa",
            "lose_seed"                   AS "opponent_seed",
            "lose_school_ncaa"            AS "opponent_school_ncaa"
    FROM    NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE   "season" BETWEEN 2014 AND 2017

    UNION ALL
    /* losers */
    SELECT  "season",
            'loss'                         AS "label",
            "lose_seed"                   AS "seed",
            "lose_school_ncaa"            AS "school_ncaa",
            "win_seed"                    AS "opponent_seed",
            "win_school_ncaa"             AS "opponent_school_ncaa"
    FROM    NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE   "season" BETWEEN 2014 AND 2017
),
results_2018 AS (                   -- already one row per team
    SELECT  "season",
            "label",
            "seed",
            "school_ncaa",
            "opponent_seed",
            "opponent_school_ncaa"
    FROM    NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS
    WHERE   "season" = 2018
),
tournament_games AS (               -- complete set 2014-present
    SELECT * FROM historical_games
    UNION ALL
    SELECT * FROM results_2018
),
team_metrics AS (                   -- convenience CTE for FE numbers
    SELECT  "season",
            UPPER("team")           AS "team_key",
            "pace_rank",
            "poss_40min",
            "pace_rating",
            "efficiency_rank",
            "pts_100poss",
            "efficiency_rating"
    FROM    NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING
),
joined AS (                         -- attach metrics for team & opponent
    SELECT
        tg."season",
        tg."label",
        tg."seed",
        tg."school_ncaa",
        tg."opponent_seed",
        tg."opponent_school_ncaa",

        tm."pace_rank",
        tm."poss_40min",
        tm."pace_rating",
        tm."efficiency_rank",
        tm."pts_100poss",
        tm."efficiency_rating",

        om."pace_rank"            AS "opp_pace_rank",
        om."poss_40min"           AS "opp_poss_40min",
        om."pace_rating"          AS "opp_pace_rating",
        om."efficiency_rank"      AS "opp_efficiency_rank",
        om."pts_100poss"          AS "opp_pts_100poss",
        om."efficiency_rating"    AS "opp_efficiency_rating"
    FROM            tournament_games      tg
    LEFT JOIN       team_metrics          tm
           ON  tm."season"   = tg."season"
           AND tm."team_key" = UPPER(tg."school_ncaa")
    LEFT JOIN       team_metrics          om
           ON  om."season"   = tg."season"
           AND om."team_key" = UPPER(tg."opponent_school_ncaa")
)
SELECT
    "season",
    "label",
    "seed",
    "school_ncaa",
    "opponent_seed",
    "opponent_school_ncaa",

    /* team metrics */
    "pace_rank",
    "poss_40min",
    "pace_rating",
    "efficiency_rank",
    "pts_100poss",
    "efficiency_rating",

    /* opponent metrics */
    "opp_pace_rank",
    "opp_poss_40min",
    "opp_pace_rating",
    "opp_efficiency_rank",
    "opp_pts_100poss",
    "opp_efficiency_rating",

    /* opponent – team differences */
    ("opp_pace_rank"       - "pace_rank")        AS "pace_rank_diff",
    ("opp_poss_40min"      - "poss_40min")       AS "poss_40min_diff",
    ("opp_pace_rating"     - "pace_rating")      AS "pace_rating_diff",
    ("opp_efficiency_rank" - "efficiency_rank")  AS "efficiency_rank_diff",
    ("opp_pts_100poss"     - "pts_100poss")      AS "pts_100poss_diff",
    ("opp_efficiency_rating" - "efficiency_rating") AS "efficiency_rating_diff"
FROM   joined
ORDER BY "season" ASC, "school_ncaa" ASC;