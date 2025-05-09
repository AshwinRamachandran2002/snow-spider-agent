WITH
-- every team that ever appeared in a match (home or away) together with the league it played in
teams_in_league AS (
    SELECT "league_id",
           "home_team_api_id" AS "team_api_id"
    FROM   "Match"
    WHERE  "home_team_api_id" IS NOT NULL
    UNION
    SELECT "league_id",
           "away_team_api_id"
    FROM   "Match"
    WHERE  "away_team_api_id" IS NOT NULL
),

-- every individual WIN (home-side or away-side)
wins AS (
    SELECT "league_id",
           "home_team_api_id" AS "team_api_id"
    FROM   "Match"
    WHERE  "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "league_id",
           "away_team_api_id"
    FROM   "Match"
    WHERE  "away_team_goal" > "home_team_goal"
),

-- total wins per (league, team)
wins_count AS (
    SELECT "league_id",
           "team_api_id",
           COUNT(*) AS "total_wins"
    FROM   wins
    GROUP BY "league_id", "team_api_id"
),

-- attach a zero to teams that never won
all_team_wins AS (
    SELECT  t."league_id",
            t."team_api_id",
            COALESCE(w."total_wins", 0) AS "total_wins"
    FROM    teams_in_league t
    LEFT JOIN wins_count w
           ON w."league_id"  = t."league_id"
          AND w."team_api_id" = t."team_api_id"
),

-- minimum wins recorded inside each league
min_wins AS (
    SELECT "league_id",
           MIN("total_wins") AS "min_wins"
    FROM   all_team_wins
    GROUP BY "league_id"
),

-- teams that own that minimum
fewest AS (
    SELECT a.*
    FROM   all_team_wins a
    JOIN   min_wins m
           ON  a."league_id"  = m."league_id"
           AND a."total_wins" = m."min_wins"
)

-- final answer: one row per league (tie-breaker → smallest team_api_id)
SELECT   l."name"           AS "league_name",
         t."team_long_name" AS "team_name",
         f."total_wins"
FROM     fewest f
JOIN     "League" l ON l."id"          = f."league_id"
JOIN     "Team"   t ON t."team_api_id" = f."team_api_id"
WHERE    f."team_api_id" = (
         SELECT MIN(f2."team_api_id")
         FROM   fewest f2
         WHERE  f2."league_id" = f."league_id"
)
ORDER BY l."name";