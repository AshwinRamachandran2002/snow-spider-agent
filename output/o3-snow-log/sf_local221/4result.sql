WITH "wins" AS (
    /* wins achieved by the home side */
    SELECT "home_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_goal" > "away_team_goal"
    
    UNION ALL
    
    /* wins achieved by the away side */
    SELECT "away_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "away_team_goal" > "home_team_goal"
),
"win_counts" AS (
    SELECT
        "team_api_id",
        COUNT(*) AS "wins"
    FROM "wins"
    GROUP BY "team_api_id"
)
SELECT
    t."team_long_name",
    wc."wins"
FROM "win_counts" wc
JOIN EU_SOCCER.EU_SOCCER."TEAM" t
      ON wc."team_api_id" = t."team_api_id"
ORDER BY wc."wins" DESC NULLS LAST
LIMIT 10;