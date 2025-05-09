WITH
    "wins_home" AS (
        SELECT
            "home_team_api_id"            AS "team_api_id",
            COUNT(*)                      AS "wins"
        FROM EU_SOCCER.EU_SOCCER.MATCH
        WHERE "home_team_goal" > "away_team_goal"
        GROUP BY "home_team_api_id"
    ),
    "wins_away" AS (
        SELECT
            "away_team_api_id"            AS "team_api_id",
            COUNT(*)                      AS "wins"
        FROM EU_SOCCER.EU_SOCCER.MATCH
        WHERE "away_team_goal" > "home_team_goal"
        GROUP BY "away_team_api_id"
    ),
    "all_wins" AS (
        SELECT * FROM "wins_home"
        UNION ALL
        SELECT * FROM "wins_away"
    ),
    "wins_per_team" AS (
        SELECT
            "team_api_id",
            SUM("wins")                   AS "total_wins"
        FROM "all_wins"
        GROUP BY "team_api_id"
    )
SELECT
    t."team_long_name"                  AS "TEAM_NAME",
    w."total_wins"                      AS "TOTAL_WINS"
FROM "wins_per_team" w
JOIN EU_SOCCER.EU_SOCCER.TEAM t
     ON w."team_api_id" = t."team_api_id"
ORDER BY w."total_wins" DESC NULLS LAST
LIMIT 10;