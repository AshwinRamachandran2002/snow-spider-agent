WITH league_team_wins AS (
  SELECT "league_id", "team_id", COUNT(*) AS "wins_in_league"
  FROM (
    SELECT "league_id", "home_team_api_id" AS "team_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "league_id", "away_team_api_id" AS "team_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "away_team_goal" > "home_team_goal"
  ) AS "league_wins"
  GROUP BY "league_id", "team_id"
),
league_min_wins AS (
  SELECT
    lw."league_id",
    lw."team_id",
    lw."wins_in_league",
    ROW_NUMBER() OVER (
      PARTITION BY lw."league_id"
      ORDER BY lw."wins_in_league" ASC, lw."team_id" ASC
    ) AS rn
  FROM league_team_wins lw
)
SELECT
  lg."name" AS "League_Name",
  t."team_long_name" AS "Team_Name",
  lm."wins_in_league" AS "Number_of_Wins"
FROM league_min_wins lm
JOIN EU_SOCCER.EU_SOCCER.TEAM t
  ON lm."team_id" = t."team_api_id"
JOIN EU_SOCCER.EU_SOCCER.LEAGUE lg
  ON lm."league_id" = lg."id"
WHERE lm.rn = 1
ORDER BY lg."name";