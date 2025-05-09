WITH season_totals AS (
    /* goals each team scored in every season */
    SELECT  "season",
            "home_team_api_id" AS "team_api_id",
            SUM("home_team_goal") AS "season_goals"
    FROM    "Match"
    GROUP BY "season", "home_team_api_id"

    UNION ALL

    SELECT  "season",
            "away_team_api_id",
            SUM("away_team_goal")
    FROM    "Match"
    GROUP BY "season", "away_team_api_id"
),
merged_seasons AS (
    /* merge the home- and away-side aggregates */
    SELECT  "season",
            "team_api_id",
            SUM("season_goals") AS "season_goals"
    FROM    season_totals
    GROUP BY "season", "team_api_id"
),
highest_per_team AS (
    /* each team’s best (highest-scoring) season */
    SELECT  "team_api_id",
            MAX("season_goals") AS "highest_season_goals"
    FROM    merged_seasons
    GROUP BY "team_api_id"
),
ordered AS (
    /* rank the values so we can pick the middle one(s) */
    SELECT  "highest_season_goals",
            ROW_NUMBER() OVER (ORDER BY "highest_season_goals") AS rn,
            COUNT(*)    OVER ()                                 AS cnt
    FROM    highest_per_team
)
SELECT  AVG("highest_season_goals") AS "median_highest_season_goals"
FROM    ordered
WHERE   rn IN ( (cnt + 1) / 2,         -- middle row (odd)
                (cnt + 2) / 2 );       -- the other middle row (even)