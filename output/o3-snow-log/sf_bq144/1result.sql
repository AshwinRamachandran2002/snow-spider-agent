/*  Tournament analysis data set (seasons 2014 – current)
    Combines tournament outcomes with pace / efficiency metrics         */

WITH base_games AS (

    /* -------- winners from historical tournament games -------- */
    SELECT
        "season",
        'win'                       AS "label",
        "win_seed"                  AS "seed",
        "win_school_ncaa"           AS "school_ncaa",
        "lose_seed"                 AS "opponent_seed",
        "lose_school_ncaa"          AS "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2014

    UNION ALL

    /* -------- losers from historical tournament games --------- */
    SELECT
        "season",
        'loss'                      AS "label",
        "lose_seed"                 AS "seed",
        "lose_school_ncaa"          AS "school_ncaa",
        "win_seed"                  AS "opponent_seed",
        "win_school_ncaa"           AS "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2014

    UNION ALL

    /* ---------------- 2018 results table ---------------------- */
    SELECT
        "season",
        "label",
        "seed",
        "school_ncaa",
        "opponent_seed",
        "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS
    WHERE "season" >= 2014
)

SELECT
    bg."season",
    bg."label",
    bg."seed",
    bg."school_ncaa",
    bg."opponent_seed",
    bg."opponent_school_ncaa",

    /* ----------- pace / efficiency: team ---------------------- */
    tm."pace_rank",
    tm."poss_40min",
    tm."pace_rating",
    tm."efficiency_rank",
    tm."pts_100poss",
    tm."efficiency_rating",

    /* -------- pace / efficiency: opponent --------------------- */
    op."pace_rank"          AS "opp_pace_rank",
    op."poss_40min"         AS "opp_poss_40min",
    op."pace_rating"        AS "opp_pace_rating",
    op."efficiency_rank"    AS "opp_efficiency_rank",
    op."pts_100poss"        AS "opp_pts_100poss",
    op."efficiency_rating"  AS "opp_efficiency_rating",

    /* -------------------- differences ------------------------- */
    (op."pace_rank"         - tm."pace_rank")         AS "pace_rank_diff",
    (op."poss_40min"        - tm."poss_40min")        AS "pace_stat_diff",
    (op."pace_rating"       - tm."pace_rating")       AS "pace_rating_diff",
    (op."efficiency_rank"   - tm."efficiency_rank")   AS "eff_rank_diff",
    (op."pts_100poss"       - tm."pts_100poss")       AS "eff_stat_diff",
    (op."efficiency_rating" - tm."efficiency_rating") AS "eff_rating_diff"

FROM       base_games                               bg
LEFT JOIN  NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING   tm
           ON tm."season" = bg."season"
          AND tm."team"   = bg."school_ncaa"
LEFT JOIN  NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING   op
           ON op."season" = bg."season"
          AND op."team"   = bg."opponent_school_ncaa"

ORDER BY   bg."season",
           bg."school_ncaa",
           bg."label" NULLS LAST;