WITH team_season_home AS (          -- goals scored by every team at home each season
    SELECT 
        "home_team_api_id"   AS team_id,
        "season",
        SUM("home_team_goal") AS goals
    FROM "Match"
    GROUP BY "home_team_api_id", "season"
),
team_season_away AS (              -- goals scored by every team away each season
    SELECT 
        "away_team_api_id"   AS team_id,
        "season",
        SUM("away_team_goal") AS goals
    FROM "Match"
    GROUP BY "away_team_api_id", "season"
),
team_season AS (                   -- total goals per team‑season
    SELECT 
        team_id,
        season,
        SUM(goals) AS season_goals
    FROM (
        SELECT * FROM team_season_home
        UNION ALL
        SELECT * FROM team_season_away
    )
    GROUP BY team_id, season
),
team_max AS (                      -- highest season‑goals for every team
    SELECT 
        team_id,
        MAX(season_goals) AS max_goals
    FROM team_season
    GROUP BY team_id
),
ordered AS (                       -- order them to pick the middle value(s)
    SELECT 
        max_goals,
        ROW_NUMBER() OVER (ORDER BY max_goals) AS rn,
        COUNT(*)   OVER ()                       AS cnt
    FROM team_max
)
SELECT 
    ROUND(AVG(max_goals), 4) AS median_highest_season_goals
FROM ordered
WHERE rn IN ( 
        CAST((cnt + 1)/2 AS INTEGER),          -- middle row for odd count
        CAST((cnt + 2)/2 AS INTEGER)           -- the two middle rows for even count
);