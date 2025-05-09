SELECT
    games."season",
    games."label",
    games."seed",
    games."school_ncaa",
    games."opponent_seed",
    games."opponent_school_ncaa",
    team_metrics."pace_rank",
    ROUND(team_metrics."poss_40min", 4) AS "poss_40min",
    ROUND(team_metrics."pace_rating", 4) AS "pace_rating",
    team_metrics."efficiency_rank",
    ROUND(team_metrics."pts_100poss", 4) AS "pts_100poss",
    ROUND(team_metrics."efficiency_rating", 4) AS "efficiency_rating",
    opp_metrics."pace_rank" AS "opp_pace_rank",
    ROUND(opp_metrics."poss_40min", 4) AS "opp_poss_40min",
    ROUND(opp_metrics."pace_rating", 4) AS "opp_pace_rating",
    opp_metrics."efficiency_rank" AS "opp_efficiency_rank",
    ROUND(opp_metrics."pts_100poss", 4) AS "opp_pts_100poss",
    ROUND(opp_metrics."efficiency_rating", 4) AS "opp_efficiency_rating",
    (opp_metrics."pace_rank" - team_metrics."pace_rank") AS "pace_rank_diff",
    ROUND(opp_metrics."poss_40min" - team_metrics."poss_40min", 4) AS "pace_stat_diff",
    ROUND(opp_metrics."pace_rating" - team_metrics."pace_rating", 4) AS "pace_rating_diff",
    (opp_metrics."efficiency_rank" - team_metrics."efficiency_rank") AS "eff_rank_diff",
    ROUND(opp_metrics."pts_100poss" - team_metrics."pts_100poss", 4) AS "eff_stat_diff",
    ROUND(opp_metrics."efficiency_rating" - team_metrics."efficiency_rating", 4) AS "eff_rating_diff"
FROM
    (
        SELECT
            tg."season",
            'win' AS "label",
            tg."win_seed" AS "seed",
            tg."win_school_ncaa" AS "school_ncaa",
            tg."lose_seed" AS "opponent_seed",
            tg."lose_school_ncaa" AS "opponent_school_ncaa"
        FROM NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES tg
        WHERE tg."season" >= 2014
        UNION ALL
        SELECT
            tg."season",
            'loss' AS "label",
            tg."lose_seed" AS "seed",
            tg."lose_school_ncaa" AS "school_ncaa",
            tg."win_seed" AS "opponent_seed",
            tg."win_school_ncaa" AS "opponent_school_ncaa"
        FROM NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES tg
        WHERE tg."season" >= 2014
    ) AS games
LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING team_metrics
    ON games."season" = team_metrics."season" AND games."school_ncaa" = team_metrics."team"
LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING opp_metrics
    ON games."season" = opp_metrics."season" AND games."opponent_school_ncaa" = opp_metrics."team"
ORDER BY games."season" ASC