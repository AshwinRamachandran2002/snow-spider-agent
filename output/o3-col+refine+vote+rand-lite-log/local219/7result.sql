WITH all_teams AS (               -- every (league,team) that ever played
    SELECT DISTINCT "league_id", "home_team_api_id" AS "team_api_id"
    FROM   "Match"
    UNION
    SELECT DISTINCT "league_id", "away_team_api_id"
    FROM   "Match"
),
home_wins AS (                     -- wins achieved at home
    SELECT "league_id",
           "home_team_api_id" AS "team_api_id",
           COUNT(*)               AS "wins"
    FROM   "Match"
    WHERE  "home_team_goal" > "away_team_goal"
    GROUP BY "league_id", "home_team_api_id"
),
away_wins AS (                     -- wins achieved away
    SELECT "league_id",
           "away_team_api_id" AS "team_api_id",
           COUNT(*)               AS "wins"
    FROM   "Match"
    WHERE  "away_team_goal" > "home_team_goal"
    GROUP BY "league_id", "away_team_api_id"
),
total_wins AS (                    -- combined home + away wins per team
    SELECT "league_id",
           "team_api_id",
           SUM("wins") AS "wins"
    FROM (SELECT * FROM home_wins
          UNION ALL
          SELECT * FROM away_wins)
    GROUP BY "league_id", "team_api_id"
),
league_team_wins AS (              -- attach zeros for teams with no wins
    SELECT  a."league_id",
            a."team_api_id",
            COALESCE(t."wins",0) AS "wins"
    FROM    all_teams  AS a
    LEFT JOIN total_wins AS t
           ON a."league_id"  = t."league_id"
          AND a."team_api_id"= t."team_api_id"
),
min_per_league AS (                -- fewest wins recorded in each league
    SELECT "league_id",
           MIN("wins") AS "min_wins"
    FROM   league_team_wins
    GROUP BY "league_id"
),
worst_team AS (                    -- choose one (smallest id) team per league
    SELECT lt."league_id",
           MIN(lt."team_api_id") AS "team_api_id",  -- tie-breaker
           lt."wins"
    FROM   league_team_wins lt
    JOIN   min_per_league  m
           ON lt."league_id" = m."league_id"
          AND lt."wins"      = m."min_wins"
    GROUP BY lt."league_id"
)
SELECT  l."name"          AS "league_name",
        tm."team_long_name" AS "team_name",
        w."wins"
FROM    worst_team  AS w
JOIN    "League"    AS l  ON l."id"          = w."league_id"
JOIN    "Team"      AS tm ON tm."team_api_id"= w."team_api_id"
ORDER BY l."name";