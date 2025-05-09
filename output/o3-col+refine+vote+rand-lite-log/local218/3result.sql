WITH season_totals AS (          -- goals each team scored in every season
    SELECT m."season",
           t."team_api_id",
           SUM(CASE
                   WHEN m."home_team_api_id" = t."team_api_id"
                        THEN m."home_team_goal"
                   ELSE m."away_team_goal"
               END)                AS "season_goals"
    FROM   "Match" AS m
    JOIN   "Team"  AS t
           ON t."team_api_id" IN (m."home_team_api_id", m."away_team_api_id")
    GROUP  BY t."team_api_id",
              m."season"
),
team_best AS (                   -- each team’s single highest-scoring season
    SELECT "team_api_id",
           MAX("season_goals") AS "max_season_goals"
    FROM   season_totals
    GROUP  BY "team_api_id"
),
ordered AS (                     -- rank those maxima so we can pick the middle value(s)
    SELECT "max_season_goals",
           ROW_NUMBER() OVER (ORDER BY "max_season_goals") AS rn,
           COUNT(*)  OVER ()                                AS cnt
    FROM   team_best
)
SELECT AVG("max_season_goals") AS "median_max_season_goals"
FROM   ordered
WHERE  rn IN ((cnt + 1) / 2, (cnt + 2) / 2);   -- handles both odd & even counts