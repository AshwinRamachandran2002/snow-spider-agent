/* 1)  Gather all goals scored by every team in every season                        */
/* 2)  Compute each team’s total goals for each season                             */
/* 3)  For every team, keep the season in which it scored the most goals           */
/* 4)  Take the median of those “best-season” goal tallies across all teams        */

SELECT
    MEDIAN("max_season_goals") AS "median_of_highest_season_goals"
FROM (
    /* step-3 : highest season-goal total for every team */
    SELECT
        "team_api_id",
        MAX("total_goals") AS "max_season_goals"
    FROM (
        /* step-2 : total goals a team scored in a given season */
        SELECT
            "season",
            "team_api_id",
            SUM("goals") AS "total_goals"
        FROM (
            /* step-1 : one row per team per match with the goals it scored */
            SELECT
                "season",
                "home_team_api_id" AS "team_api_id",
                "home_team_goal"   AS "goals"
            FROM EU_SOCCER.EU_SOCCER.MATCH
            UNION ALL
            SELECT
                "season",
                "away_team_api_id" AS "team_api_id",
                "away_team_goal"   AS "goals"
            FROM EU_SOCCER.EU_SOCCER.MATCH
        ) AS match_goals
        WHERE "team_api_id" IS NOT NULL
        GROUP BY "season", "team_api_id"
    ) AS season_totals
    GROUP BY "team_api_id"
) AS team_best_seasons;