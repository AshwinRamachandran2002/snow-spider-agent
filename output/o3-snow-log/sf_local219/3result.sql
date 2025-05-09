WITH all_teams AS (     -- every team that ever played in a league
    SELECT DISTINCT "league_id", "home_team_api_id"  AS "team_api_id"
    FROM   "EU_SOCCER"."EU_SOCCER"."MATCH"
    UNION
    SELECT DISTINCT "league_id", "away_team_api_id"  AS "team_api_id"
    FROM   "EU_SOCCER"."EU_SOCCER"."MATCH"
),
wins AS (                -- each individual win (home or away)
    SELECT "league_id", "home_team_api_id" AS "team_api_id", 1 AS "win_cnt"
    FROM   "EU_SOCCER"."EU_SOCCER"."MATCH"
    WHERE  "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "league_id", "away_team_api_id" AS "team_api_id", 1 AS "win_cnt"
    FROM   "EU_SOCCER"."EU_SOCCER"."MATCH"
    WHERE  "away_team_goal" > "home_team_goal"
),
wins_agg AS (            -- total wins per team in each league
    SELECT "league_id",
           "team_api_id",
           SUM("win_cnt") AS "total_wins"
    FROM   wins
    GROUP BY "league_id", "team_api_id"
),
teams_with_wins AS (     -- include teams with zero wins
    SELECT a."league_id",
           a."team_api_id",
           COALESCE(w."total_wins", 0) AS "total_wins"
    FROM   all_teams a
    LEFT  JOIN wins_agg w
           ON a."league_id"  = w."league_id"
          AND a."team_api_id" = w."team_api_id"
),
ranked AS (              -- pick a single lowest-win team per league
    SELECT t."league_id",
           l."name"           AS "league_name",
           t."team_api_id",
           tm."team_long_name",
           t."total_wins",
           ROW_NUMBER() OVER (PARTITION BY t."league_id"
                              ORDER BY t."total_wins" ASC,
                                       t."team_api_id" ASC) AS rn
    FROM   teams_with_wins t
    LEFT  JOIN "EU_SOCCER"."EU_SOCCER"."LEAGUE" l
           ON t."league_id"   = l."id"
    LEFT  JOIN "EU_SOCCER"."EU_SOCCER"."TEAM"   tm
           ON t."team_api_id" = tm."team_api_id"
)
SELECT  "league_id",
        "league_name",
        "team_api_id",
        "team_long_name",
        "total_wins"
FROM    ranked
WHERE   rn = 1                  -- one team per league (ties broken by team_api_id)
ORDER BY "league_id";