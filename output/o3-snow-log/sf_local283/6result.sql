WITH match_points AS (
    /* One record per team per match with the points it earned */
    SELECT 
        "season",
        "league_id",
        "home_team_api_id"       AS "team_api_id",
        CASE 
            WHEN "home_team_goal" > "away_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0
        END                      AS "points"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    
    UNION ALL
    
    SELECT 
        "season",
        "league_id",
        "away_team_api_id"       AS "team_api_id",
        CASE 
            WHEN "away_team_goal" > "home_team_goal" THEN 3
            WHEN "away_team_goal" = "home_team_goal" THEN 1
            ELSE 0
        END                      AS "points"
    FROM EU_SOCCER.EU_SOCCER.MATCH
),

season_team_points AS (
    /* Total points each team collected in a given season & league */
    SELECT
        "season",
        "league_id",
        "team_api_id",
        SUM("points")            AS "total_points"
    FROM match_points
    GROUP BY
        "season",
        "league_id",
        "team_api_id"
),

ranked_champions AS (
    /* Rank teams inside each (season, league) by total points */
    SELECT
        stp.*,
        ROW_NUMBER() OVER (
            PARTITION BY "season", "league_id"
            ORDER BY "total_points" DESC NULLS LAST, "team_api_id"
        )                       AS "rn"
    FROM season_team_points stp
)

SELECT
    t."team_long_name"          AS "champion_team",
    l."name"                    AS "league_name",
    c."name"                    AS "country_name",
    rc."season",
    rc."total_points"
FROM ranked_champions       rc
JOIN EU_SOCCER.EU_SOCCER.TEAM     t ON rc."team_api_id" = t."team_api_id"
JOIN EU_SOCCER.EU_SOCCER.LEAGUE   l ON rc."league_id"   = l."id"
JOIN EU_SOCCER.EU_SOCCER.COUNTRY  c ON l."country_id"   = c."id"
WHERE rc."rn" = 1
ORDER BY
    rc."season",
    c."name",
    l."name";