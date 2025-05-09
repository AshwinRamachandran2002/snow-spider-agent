WITH teams_in_league AS (
    SELECT DISTINCT "league_id", "home_team_api_id" AS "team_api_id"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
    UNION
    SELECT DISTINCT "league_id", "away_team_api_id" AS "team_api_id"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
),
wins_per_team AS (
    SELECT "league_id", "team_api_id", COUNT(*) AS "wins"
    FROM (
        SELECT "league_id", "home_team_api_id" AS "team_api_id"
        FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
        WHERE "home_team_goal" > "away_team_goal"
        UNION ALL
        SELECT "league_id", "away_team_api_id" AS "team_api_id"
        FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
        WHERE "away_team_goal" > "home_team_goal"
    ) AS "wins_per_match"
    GROUP BY "league_id", "team_api_id"
),
wins_per_team_full AS (
    SELECT t."league_id", t."team_api_id", COALESCE(w."wins", 0) AS "total_wins"
    FROM teams_in_league t
    LEFT JOIN wins_per_team w
        ON t."league_id" = w."league_id" AND t."team_api_id" = w."team_api_id"
),
min_wins_per_league AS (
    SELECT "league_id", MIN("total_wins") AS "min_wins"
    FROM wins_per_team_full
    GROUP BY "league_id"
),
teams_with_min_wins AS (
    SELECT w.*, ROW_NUMBER() OVER (PARTITION BY w."league_id" ORDER BY w."team_api_id") AS rn
    FROM wins_per_team_full w
    JOIN min_wins_per_league m
        ON w."league_id" = m."league_id" AND w."total_wins" = m."min_wins"
)
SELECT l."name" AS "League_Name", t."team_long_name" AS "Team_Name", tw."total_wins" AS "Total_Wins"
FROM teams_with_min_wins tw
JOIN "EU_SOCCER"."EU_SOCCER"."LEAGUE" l ON tw."league_id" = l."id"
JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" t ON tw."team_api_id" = t."team_api_id"
WHERE tw.rn = 1
ORDER BY "League_Name";