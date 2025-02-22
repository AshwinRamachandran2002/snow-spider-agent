-- Task: For each team in each match, calculate the points earned by that team in that match, awarding 3 points for a win, 1 point for a tie, and 0 points for a loss. Return the team name, league, season, match date, opponent team name, result (Win/Loss/Tie), and points earned.
WITH TABLE_1 AS (
    SELECT 
        MATCH."id",
        COUNTRY."name" AS country_name, 
        LEAGUE."name" AS league_name, 
        MATCH."season", 
        MATCH."stage", 
        MATCH."date",
        HT."team_long_name" AS home_team,
        AT."team_long_name" AS away_team,
        MATCH."home_team_goal", 
        MATCH."away_team_goal",
        CASE
            WHEN MATCH."home_team_goal" > MATCH."away_team_goal" THEN 'Win'
            WHEN MATCH."home_team_goal" < MATCH."away_team_goal" THEN 'Loss'
            ELSE 'Tie'
        END AS home_team_result, 
        CASE
            WHEN MATCH."away_team_goal" > MATCH."home_team_goal" THEN 'Win'
            WHEN MATCH."away_team_goal" < MATCH."home_team_goal" THEN 'Loss'
            ELSE 'Tie'
        END AS away_team_result
    FROM EU_SOCCER.EU_SOCCER.MATCH
    JOIN EU_SOCCER.EU_SOCCER.COUNTRY ON COUNTRY."id" = MATCH."country_id"
    JOIN EU_SOCCER.EU_SOCCER.LEAGUE ON LEAGUE."id" = MATCH."league_id"
    LEFT JOIN EU_SOCCER.EU_SOCCER.TEAM AS HT ON HT."team_api_id" = MATCH."home_team_api_id"
    LEFT JOIN EU_SOCCER.EU_SOCCER.TEAM AS AT ON AT."team_api_id" = MATCH."away_team_api_id"
),
HOME_TEAM AS (
    SELECT 
        "id",
        country_name, 
        league_name, 
        "season", 
        "stage", 
        "date",
        home_team AS team, 
        away_team AS opponent_team,
        'Home' AS team_type,
        "home_team_goal" AS goals_scored,
        "away_team_goal" AS goals_conceded,
        home_team_result AS result
    FROM TABLE_1
),
AWAY_TEAM AS (
    SELECT 
        "id",
        country_name, 
        league_name, 
        "season", 
        "stage", 
        "date",
        away_team AS team, 
        home_team AS opponent_team,
        'Away' AS team_type,
        "away_team_goal" AS goals_scored,
        "home_team_goal" AS goals_conceded,
        away_team_result AS result
    FROM TABLE_1
), 
TABLE_2 AS (
    SELECT * 
    FROM HOME_TEAM
    UNION ALL
    SELECT * 
    FROM AWAY_TEAM
),
TABLE_3 AS (
    SELECT *, 
        CASE 
            WHEN result = 'Win' THEN 3
            WHEN result = 'Tie' THEN 1
            ELSE 0
        END AS points
    FROM TABLE_2
)
SELECT team, league_name, "season", "date", opponent_team, result, points
FROM TABLE_3
ORDER BY "date" ASC, team;