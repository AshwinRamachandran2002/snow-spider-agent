SELECT
    tg."season",
    tg."label",
    tg."seed",
    tg."school_ncaa",
    tg."opponent_seed",
    tg."opponent_school_ncaa",
    tm."pace_rank",
    ROUND(tm."poss_40min", 4) AS "poss_40min",
    ROUND(tm."pace_rating", 4) AS "pace_rating",
    tm."efficiency_rank",
    ROUND(tm."pts_100poss", 4) AS "pts_100poss",
    ROUND(tm."efficiency_rating", 4) AS "efficiency_rating",
    opp_tm."pace_rank" AS "opp_pace_rank",
    ROUND(opp_tm."poss_40min", 4) AS "opp_poss_40min",
    ROUND(opp_tm."pace_rating", 4) AS "opp_pace_rating",
    opp_tm."efficiency_rank" AS "opp_efficiency_rank",
    ROUND(opp_tm."pts_100poss", 4) AS "opp_pts_100poss",
    ROUND(opp_tm."efficiency_rating", 4) AS "opp_efficiency_rating",
    (opp_tm."pace_rank" - tm."pace_rank") AS "pace_rank_diff",
    ROUND(opp_tm."poss_40min" - tm."poss_40min", 4) AS "pace_stat_diff",
    ROUND(opp_tm."pace_rating" - tm."pace_rating", 4) AS "pace_rating_diff",
    (opp_tm."efficiency_rank" - tm."efficiency_rank") AS "eff_rank_diff",
    ROUND(opp_tm."pts_100poss" - tm."pts_100poss", 4) AS "eff_stat_diff",
    ROUND(opp_tm."efficiency_rating" - tm."efficiency_rating", 4) AS "eff_rating_diff"
FROM
    (
        SELECT
            "season",
            'win' AS "label",
            "win_seed" AS "seed",
            "win_school_ncaa" AS "school_ncaa",
            "lose_seed" AS "opponent_seed",
            "lose_school_ncaa" AS "opponent_school_ncaa"
        FROM "NCAA_INSIGHTS"."NCAA"."MBB_HISTORICAL_TOURNAMENT_GAMES"
        WHERE "season" >= 2014

        UNION ALL

        SELECT
            "season",
            'loss' AS "label",
            "lose_seed" AS "seed",
            "lose_school_ncaa" AS "school_ncaa",
            "win_seed" AS "opponent_seed",
            "win_school_ncaa" AS "opponent_school_ncaa"
        FROM "NCAA_INSIGHTS"."NCAA"."MBB_HISTORICAL_TOURNAMENT_GAMES"
        WHERE "season" >= 2014
    ) AS tg
LEFT JOIN "NCAA_INSIGHTS"."NCAA"."FEATURE_ENGINEERING" tm
    ON tg."school_ncaa" = tm."team" AND tg."season" = tm."season"
LEFT JOIN "NCAA_INSIGHTS"."NCAA"."FEATURE_ENGINEERING" opp_tm
    ON tg."opponent_school_ncaa" = opp_tm."team" AND tg."season" = opp_tm."season"
ORDER BY tg."season", tg."school_ncaa";