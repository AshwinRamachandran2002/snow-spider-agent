SELECT lw."league_id", l."name" AS "league_name", lw."team_api_id" AS "team_id",
       t."team_long_name", lw."total_wins" AS "wins"
FROM (
  SELECT total_wins_per_team."league_id", MIN(total_wins_per_team."team_api_id") AS "team_api_id", total_wins_per_team."total_wins"
  FROM (
    SELECT m1."league_id", m1."team_api_id", SUM(m1."wins") AS "total_wins"
    FROM (
      SELECT "league_id", "home_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
      FROM "Match"
      WHERE "home_team_goal" > "away_team_goal"
      GROUP BY "league_id", "home_team_api_id"
      UNION ALL
      SELECT "league_id", "away_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
      FROM "Match"
      WHERE "away_team_goal" > "home_team_goal"
      GROUP BY "league_id", "away_team_api_id"
    ) m1
    GROUP BY m1."league_id", m1."team_api_id"
  ) total_wins_per_team
  INNER JOIN (
    SELECT min_wins."league_id", MIN(min_wins."total_wins") AS "min_wins"
    FROM (
      SELECT m2."league_id", m2."team_api_id", SUM(m2."wins") AS "total_wins"
      FROM (
        SELECT "league_id", "home_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
        FROM "Match"
        WHERE "home_team_goal" > "away_team_goal"
        GROUP BY "league_id", "home_team_api_id"
        UNION ALL
        SELECT "league_id", "away_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
        FROM "Match"
        WHERE "away_team_goal" > "home_team_goal"
        GROUP BY "league_id", "away_team_api_id"
      ) m2
      GROUP BY m2."league_id", m2."team_api_id"
    ) min_wins
    GROUP BY min_wins."league_id"
  ) min_wins_per_league
  ON total_wins_per_team."league_id" = min_wins_per_league."league_id"
  AND total_wins_per_team."total_wins" = min_wins_per_league."min_wins"
  GROUP BY total_wins_per_team."league_id", total_wins_per_team."total_wins"
) lw
JOIN "Team" t ON lw."team_api_id" = t."team_api_id"
JOIN "League" l ON lw."league_id" = l."id"
ORDER BY lw."league_id";