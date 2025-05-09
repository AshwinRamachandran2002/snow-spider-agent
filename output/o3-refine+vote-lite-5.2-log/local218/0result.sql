WITH team_season_goals AS (               -- goals of every team in every season
    SELECT "home_team_api_id" AS team_id,
           "season",
           SUM("home_team_goal") AS goals
    FROM "Match"
    GROUP BY "home_team_api_id", "season"

    UNION ALL

    SELECT "away_team_api_id" AS team_id,
           "season",
           SUM("away_team_goal") AS goals
    FROM "Match"
    GROUP BY "away_team_api_id", "season"
),
team_max_goals AS (                       -- highest‑scoring season of each team
    SELECT team_id,
           MAX(goals) AS max_goals
    FROM team_season_goals
    GROUP BY team_id
),
ordered AS (                              -- order them to locate the median
    SELECT max_goals,
           ROW_NUMBER() OVER (ORDER BY max_goals) AS rn,
           COUNT(*)  OVER ()               AS n
    FROM team_max_goals
),
median_candidates AS (                    -- the middle value(s)
    SELECT max_goals, n
    FROM ordered
    WHERE (n % 2 = 1 AND rn = (n + 1) / 2)              -- odd count → single middle row
       OR (n % 2 = 0 AND (rn = n / 2 OR rn = n / 2 + 1)) -- even count → two middle rows
)
SELECT
    CASE
        WHEN (SELECT n FROM median_candidates LIMIT 1) % 2 = 1
             THEN MAX(max_goals)          -- odd: that single middle value
        ELSE AVG(max_goals)               -- even: average of the two
    END  AS median_highest_season_goals
FROM median_candidates;