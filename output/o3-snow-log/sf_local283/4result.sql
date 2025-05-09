WITH match_points AS (
    /* 1.  Assign points to every team in every match (home + away) */
    SELECT
        "season",
        "league_id",
        "home_team_api_id"           AS "team_api_id",
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0
        END                          AS "points"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    
    UNION ALL
    
    SELECT
        "season",
        "league_id",
        "away_team_api_id"           AS "team_api_id",
        CASE
            WHEN "away_team_goal" > "home_team_goal" THEN 3
            WHEN "away_team_goal" = "home_team_goal" THEN 1
            ELSE 0
        END                          AS "points"
    FROM EU_SOCCER.EU_SOCCER.MATCH
),
season_team_points AS (
    /* 2.  Total points per team per season within each league */
    SELECT
        "season",
        "league_id",
        "team_api_id",
        SUM("points") AS "total_points"
    FROM match_points
    GROUP BY
        "season",
        "league_id",
        "team_api_id"
),
champions AS (
    /* 3.  Determine the champion (highest points) for every league-season */
    SELECT
        stp."season",
        stp."league_id",
        stp."team_api_id",
        stp."total_points",
        ROW_NUMBER() OVER (
            PARTITION BY stp."season", stp."league_id"
            ORDER BY stp."total_points" DESC, stp."team_api_id" ASC
        ) AS "rn"
    FROM season_team_points stp
)
SELECT
    c."name"                AS "country",
    l."name"                AS "league",
    t."team_long_name"      AS "champion_team",
    ch."season",
    ch."total_points"
FROM champions ch
JOIN EU_SOCCER.EU_SOCCER.LEAGUE   l ON l."id" = ch."league_id"
JOIN EU_SOCCER.EU_SOCCER.COUNTRY  c ON c."id" = l."country_id"
JOIN EU_SOCCER.EU_SOCCER.TEAM     t ON t."team_api_id" = ch."team_api_id"
WHERE ch."rn" = 1
ORDER BY
    ch."season" ASC,
    c."name"  ASC,
    l."name"  ASC;