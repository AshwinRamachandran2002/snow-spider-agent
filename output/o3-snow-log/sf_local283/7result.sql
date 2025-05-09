WITH "match_points" AS (
    /* 1.  Assign points to every team in every match ------------------------*/
    SELECT  
        "match_api_id",
        "season",
        "league_id",
        "home_team_api_id"      AS "team_api_id",
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0
        END                     AS "points"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_goal" IS NOT NULL
      AND "away_team_goal" IS NOT NULL

    UNION ALL

    SELECT
        "match_api_id",
        "season",
        "league_id",
        "away_team_api_id"      AS "team_api_id",
        CASE
            WHEN "away_team_goal" > "home_team_goal" THEN 3
            WHEN "away_team_goal" = "home_team_goal" THEN 1
            ELSE 0
        END                     AS "points"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_goal" IS NOT NULL
      AND "away_team_goal" IS NOT NULL
),
/* 2.  Total points for every team per season & league -----------------------*/
"team_season_points" AS (
    SELECT
        "season",
        "league_id",
        "team_api_id",
        SUM("points")           AS "total_points"
    FROM "match_points"
    GROUP BY "season", "league_id", "team_api_id"
),
/* 3.  Rank teams to find the champion for each season & league --------------*/
"ranked" AS (
    SELECT
        tsp.*,
        ROW_NUMBER() OVER (
            PARTITION BY "season", "league_id"
            ORDER BY "total_points" DESC, "team_api_id" ASC
        )                       AS "rn"
    FROM "team_season_points" tsp
)
/* 4.  Return champions with league & country names --------------------------*/
SELECT
    r."season",
    t."team_long_name"                  AS "champion_team",
    l."name"                            AS "league_name",
    c."name"                            AS "country_name",
    r."total_points"
FROM "ranked" r
JOIN EU_SOCCER.EU_SOCCER."TEAM"     t ON r."team_api_id" = t."team_api_id"
JOIN EU_SOCCER.EU_SOCCER."LEAGUE"   l ON r."league_id"   = l."id"
JOIN EU_SOCCER.EU_SOCCER."COUNTRY"  c ON l."country_id"  = c."id"
WHERE r."rn" = 1
ORDER BY r."season", "league_name";