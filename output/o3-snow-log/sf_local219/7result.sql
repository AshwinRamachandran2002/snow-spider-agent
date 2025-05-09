WITH "all_team_league" AS (           -- every (league , team) that ever played
    SELECT DISTINCT 
           "league_id",
           "home_team_api_id" AS "team_api_id"
    FROM   "EU_SOCCER"."EU_SOCCER"."MATCH"
    WHERE  "home_team_api_id" IS NOT NULL
    UNION
    SELECT DISTINCT 
           "league_id",
           "away_team_api_id"
    FROM   "EU_SOCCER"."EU_SOCCER"."MATCH"
    WHERE  "away_team_api_id" IS NOT NULL
),

-- number of wins each team earned in each league
"win_counts" AS (
    SELECT 
        "league_id",
        "team_api_id",
        SUM("win_flag") AS "wins"
    FROM (
        SELECT 
            "league_id",
            "home_team_api_id" AS "team_api_id",
            CASE WHEN "home_team_goal" > "away_team_goal" THEN 1 ELSE 0 END AS "win_flag"
        FROM   "EU_SOCCER"."EU_SOCCER"."MATCH"
        
        UNION ALL
        
        SELECT 
            "league_id",
            "away_team_api_id",
            CASE WHEN "away_team_goal" > "home_team_goal" THEN 1 ELSE 0 END
        FROM   "EU_SOCCER"."EU_SOCCER"."MATCH"
    ) sub
    GROUP BY "league_id", "team_api_id"
),

-- attach zero wins to teams that never won
"team_wins" AS (
    SELECT 
        atl."league_id",
        atl."team_api_id",
        COALESCE(wc."wins", 0) AS "wins"
    FROM   "all_team_league"        atl
    LEFT  JOIN "win_counts"         wc
           ON  atl."league_id"   = wc."league_id"
           AND atl."team_api_id" = wc."team_api_id"
),

-- pick a single lowest–winning team per league (ties broken by smaller team_id)
"ranked" AS (
    SELECT 
        tw."league_id",
        tw."team_api_id",
        tw."wins",
        ROW_NUMBER() OVER (PARTITION BY tw."league_id"
                           ORDER BY tw."wins" ASC,
                                    tw."team_api_id" ASC) AS "rn"
    FROM   "team_wins" tw
)

SELECT 
    r."league_id",
    lg."name"            AS "league_name",
    r."team_api_id",
    tm."team_long_name",
    r."wins"
FROM   "ranked"                 r
JOIN   "EU_SOCCER"."EU_SOCCER"."LEAGUE" lg
       ON lg."id" = r."league_id"
LEFT  JOIN "EU_SOCCER"."EU_SOCCER"."TEAM"   tm
       ON tm."team_api_id" = r."team_api_id"
WHERE  r."rn" = 1
ORDER BY r."league_id";