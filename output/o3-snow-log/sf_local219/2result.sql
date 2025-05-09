WITH "wins" AS (             -- every individual match victory
    SELECT "league_id",
           "home_team_api_id" AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
    WHERE  "home_team_goal" > "away_team_goal"

    UNION ALL

    SELECT "league_id",
           "away_team_api_id" AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
    WHERE  "away_team_goal" > "home_team_goal"
),

"wins_total" AS (            -- total wins per team per league
    SELECT "league_id",
           "team_api_id",
           COUNT(*) AS "wins"
    FROM   "wins"
    GROUP  BY "league_id", "team_api_id"
),

"all_teams" AS (             -- every team that ever appeared in a league
    SELECT DISTINCT "league_id",
                    "home_team_api_id" AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
    UNION
    SELECT DISTINCT "league_id",
                    "away_team_api_id" AS "team_api_id"
    FROM   EU_SOCCER.EU_SOCCER.MATCH
),

"teams_wins" AS (            -- attach win counts, defaulting to zero
    SELECT at."league_id",
           at."team_api_id",
           COALESCE(wt."wins", 0) AS "wins"
    FROM   "all_teams"   at
    LEFT  JOIN "wins_total" wt
           ON  at."league_id"  = wt."league_id"
           AND at."team_api_id" = wt."team_api_id"
)

SELECT  l."name"            AS "league_name",
        t."team_long_name"  AS "team_name",
        tw."wins"
FROM    "teams_wins" tw
JOIN    EU_SOCCER.EU_SOCCER.LEAGUE l
        ON tw."league_id" = l."id"
JOIN    EU_SOCCER.EU_SOCCER.TEAM  t
        ON tw."team_api_id" = t."team_api_id"
QUALIFY ROW_NUMBER() OVER (PARTITION BY tw."league_id"
                           ORDER BY tw."wins" ASC, tw."team_api_id" ASC) = 1   -- single lowest-win team per league
ORDER BY l."id";