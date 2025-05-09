WITH match_points AS (          -- 1. 1 row per team per match with the points earned
    SELECT 
        "league_id",
        "season",
        "home_team_api_id"  AS "team_api_id",
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN 3        -- home win
            WHEN "home_team_goal" = "away_team_goal" THEN 1        -- draw
            ELSE 0                                                 -- loss
        END                    AS "points"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_goal" IS NOT NULL 
      AND "away_team_goal" IS NOT NULL

    UNION ALL

    SELECT 
        "league_id",
        "season",
        "away_team_api_id"  AS "team_api_id",
        CASE
            WHEN "away_team_goal" > "home_team_goal" THEN 3        -- away win
            WHEN "away_team_goal" = "home_team_goal" THEN 1        -- draw
            ELSE 0                                                 -- loss
        END                    AS "points"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_goal" IS NOT NULL 
      AND "away_team_goal" IS NOT NULL
),                               -- 2. total points per team / league / season
season_team_points AS (
    SELECT
        "league_id",
        "season",
        "team_api_id",
        SUM("points") AS "total_points"
    FROM match_points
    GROUP BY
        "league_id",
        "season",
        "team_api_id"
),                               -- 3. pick champion (max points) per season & league
season_champions AS (
    SELECT
        stp."league_id",
        stp."season",
        stp."team_api_id",
        stp."total_points",
        ROW_NUMBER() OVER (PARTITION BY stp."league_id", stp."season" 
                           ORDER BY stp."total_points" DESC, stp."team_api_id") AS "rk"
    FROM season_team_points stp
)
SELECT
    t."team_long_name"      AS "champion_team",
    l."name"                AS "league_name",
    c."name"                AS "country_name",
    sc."season",
    sc."total_points"
FROM season_champions sc
JOIN EU_SOCCER.EU_SOCCER.TEAM    t ON sc."team_api_id" = t."team_api_id"
JOIN EU_SOCCER.EU_SOCCER.LEAGUE  l ON sc."league_id"  = l."id"
JOIN EU_SOCCER.EU_SOCCER.COUNTRY c ON l."country_id"  = c."id"
WHERE sc."rk" = 1                         -- keep only the champion per season
ORDER BY sc."season", c."name", l."name";