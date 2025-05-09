/*--------------------------------------------------------------------
  NCAA MEN’S TOURNAMENT – TEAM / OPPONENT METRICS  (2014 SEASON → PRESENT)

  Creates one record for every team-view of a tournament game
  (win & loss rows), enriched with each school’s pace & efficiency
  metrics together with the opponent’s numbers and the head-to-head
  differences.  Includes the 2018 results file to cover the 2018
  tournament, and everything from 2014 season forward.
--------------------------------------------------------------------*/
WITH historical AS (          -- 2014+ results from the long-term file
    SELECT
        "season",
        'win'  AS "label",
        "win_seed"          AS "seed",
        "win_school_ncaa"   AS "school_ncaa",
        "lose_seed"         AS "opponent_seed",
        "lose_school_ncaa"  AS "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2014

    UNION ALL               -- losing side of the same games
    SELECT
        "season",
        'loss' AS "label",
        "lose_seed"         AS "seed",
        "lose_school_ncaa"  AS "school_ncaa",
        "win_seed"          AS "opponent_seed",
        "win_school_ncaa"   AS "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2014
),

results_2018 AS (            -- dedicated 2018 results file
    SELECT
        "season",
        "label",
        "seed",
        "school_ncaa",
        "opponent_seed",
        "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS
),

tournament_games AS (        -- combine both sources
    SELECT * FROM historical
    UNION ALL
    SELECT * FROM results_2018
)

SELECT
    tg."season",
    tg."label",
    tg."seed",
    tg."school_ncaa",
    tg."opponent_seed",
    tg."opponent_school_ncaa",

    /*  TEAM METRICS  */
    fe."pace_rank",
    fe."poss_40min",
    fe."pace_rating",
    fe."efficiency_rank",
    fe."pts_100poss",
    fe."efficiency_rating",

    /*  OPPONENT METRICS  */
    fe_opp."pace_rank"        AS "opp_pace_rank",
    fe_opp."poss_40min"       AS "opp_poss_40min",
    fe_opp."pace_rating"      AS "opp_pace_rating",
    fe_opp."efficiency_rank"  AS "opp_efficiency_rank",
    fe_opp."pts_100poss"      AS "opp_pts_100poss",
    fe_opp."efficiency_rating"AS "opp_efficiency_rating",

    /*  DIFFERENCES (opponent – team)  */
    fe_opp."pace_rank"        - fe."pace_rank"        AS "pace_rank_diff",
    fe_opp."poss_40min"       - fe."poss_40min"       AS "poss_40min_diff",
    fe_opp."pace_rating"      - fe."pace_rating"      AS "pace_rating_diff",
    fe_opp."efficiency_rank"  - fe."efficiency_rank"  AS "eff_rank_diff",
    fe_opp."pts_100poss"      - fe."pts_100poss"      AS "pts_100poss_diff",
    fe_opp."efficiency_rating"- fe."efficiency_rating"AS "eff_rating_diff"

FROM  tournament_games tg
LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING fe
       ON  fe."season" = tg."season"
       AND UPPER(fe."team") = UPPER(tg."school_ncaa")

LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING fe_opp
       ON  fe_opp."season" = tg."season"
       AND UPPER(fe_opp."team") = UPPER(tg."opponent_school_ncaa");