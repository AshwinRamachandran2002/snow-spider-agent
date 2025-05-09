/*-----------------------------------------------------------
  Determine the champion (highest-point team) for every season
  in every league, awarding 3-1-0 points for win-draw-loss.
-----------------------------------------------------------*/
WITH points_per_match AS (   -- give each team its points from every match
    /*  Home side */
    SELECT
        "season",
        "league_id",
        "home_team_api_id"  AS "team_api_id",
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0
        END                 AS "points"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_api_id" IS NOT NULL

    UNION ALL

    /*  Away side */
    SELECT
        "season",
        "league_id",
        "away_team_api_id"  AS "team_api_id",
        CASE
            WHEN "away_team_goal" > "home_team_goal" THEN 3
            WHEN "away_team_goal" = "home_team_goal" THEN 1
            ELSE 0
        END                 AS "points"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "away_team_api_id" IS NOT NULL
),

season_team_points AS (      -- total season points for every team
    SELECT
        "season",
        "league_id",
        "team_api_id",
        SUM("points") AS "total_points"
    FROM points_per_match
    GROUP BY "season", "league_id", "team_api_id"
),

ranked_season_teams AS (     -- rank teams within each league & season
    SELECT
        stp.*,
        RANK() OVER (PARTITION BY "season", "league_id"
                     ORDER BY "total_points" DESC) AS "rk"
    FROM season_team_points stp
)

SELECT
    c."name"          AS "country",
    l."name"          AS "league",
    r."season",
    t."team_long_name" AS "champion_team",
    r."total_points"
FROM ranked_season_teams r
JOIN EU_SOCCER.EU_SOCCER.TEAM    t ON r."team_api_id" = t."team_api_id"
JOIN EU_SOCCER.EU_SOCCER.LEAGUE  l ON r."league_id"   = l."id"
JOIN EU_SOCCER.EU_SOCCER.COUNTRY c ON l."country_id"  = c."id"
WHERE r."rk" = 1                      -- keep only the champion(s)
ORDER BY
    r."season",
    c."name",
    l."name",
    r."total_points" DESC NULLS LAST;