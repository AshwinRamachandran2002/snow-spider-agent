WITH all_appearances AS (            -- every team that ever played in a league
       SELECT "league_id",
              "home_team_api_id" AS "team_api_id"
       FROM   "Match"
       UNION
       SELECT "league_id",
              "away_team_api_id"
       FROM   "Match"),

wins AS (                             -- every individual win (home OR away)
       SELECT "league_id",
              "team_api_id",
              COUNT(*) AS "wins"
       FROM  (SELECT "league_id",
                     "home_team_api_id" AS "team_api_id"
              FROM   "Match"
              WHERE  "home_team_goal" > "away_team_goal"
              UNION ALL
              SELECT "league_id",
                     "away_team_api_id"
              FROM   "Match"
              WHERE  "away_team_goal" > "home_team_goal")
       GROUP BY "league_id","team_api_id"),

per_team AS (                         -- total wins per team (zero-wins kept)
       SELECT a."league_id",
              a."team_api_id",
              COALESCE(w."wins",0) AS "total_wins"
       FROM   all_appearances a
       LEFT JOIN wins w
              ON  a."league_id"   = w."league_id"
              AND a."team_api_id" = w."team_api_id"),

min_per_league AS (                   -- minimum win count in each league
       SELECT "league_id",
              MIN("total_wins") AS "min_wins"
       FROM   per_team
       GROUP  BY "league_id"),

one_team_per_league AS (              -- pick one team owning that minimum
       SELECT p."league_id",
              p."team_api_id",
              p."total_wins"
       FROM   per_team p
       JOIN   min_per_league m
              ON  p."league_id" = m."league_id"
              AND p."total_wins"= m."min_wins"
       GROUP  BY p."league_id")      -- SQLite keeps smallest team_api_id on tie
       
SELECT l."name"           AS "league_name",
       t."team_long_name" AS "team_with_fewest_wins",
       o."total_wins"
FROM   one_team_per_league o
JOIN   "League" l ON l."id"          = o."league_id"
JOIN   "Team"   t ON t."team_api_id" = o."team_api_id"
ORDER  BY l."id";