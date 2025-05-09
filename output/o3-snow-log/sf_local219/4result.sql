WITH all_teams AS (          -- every team that has appeared in each league
    SELECT "league_id",
           "home_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    UNION
    SELECT "league_id",
           "away_team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
),
wins AS (                    -- every individual match-win (home or away)
    SELECT "league_id",
           "home_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "league_id",
           "away_team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "away_team_goal" > "home_team_goal"
),
win_counts AS (              -- total wins by team within each league
    SELECT "league_id",
           "team_api_id",
           COUNT(*) AS "wins"
    FROM wins
    GROUP BY "league_id", "team_api_id"
),
team_wins AS (               -- attach zero wins to teams that never won
    SELECT t."league_id",
           t."team_api_id",
           COALESCE(w."wins", 0) AS "wins"
    FROM all_teams t
    LEFT JOIN win_counts w
      ON t."league_id" = w."league_id"
     AND t."team_api_id" = w."team_api_id"
),
ranked AS (                  -- choose one (any) lowest-win team per league
    SELECT tw.*,
           ROW_NUMBER() OVER (PARTITION BY tw."league_id"
                              ORDER BY tw."wins" ASC,
                                       tw."team_api_id" ASC) AS rn
    FROM team_wins tw
)
SELECT r."league_id",
       l."name"           AS "league_name",
       r."team_api_id",
       tm."team_long_name",
       r."wins"
FROM ranked r
JOIN EU_SOCCER.EU_SOCCER.LEAGUE l
  ON r."league_id" = l."id"
JOIN EU_SOCCER.EU_SOCCER.TEAM tm
  ON r."team_api_id" = tm."team_api_id"
WHERE r.rn = 1                -- one team per league (fewest wins)
ORDER BY r."league_id";