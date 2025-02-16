-- Task: In each league, considering all seasons, find the total number of match wins for each team based on comparing home and away goals.

WITH match_view AS (
    SELECT
        M.id,
        L.name AS league,
        M.season,
        T.team_long_name AS home_team,
        TM.team_long_name AS away_team,
        M.home_team_goal,
        M.away_team_goal
    FROM
        Match M
    LEFT JOIN
        League L ON M.league_id = L.id
    LEFT JOIN
        Team T ON M.home_team_api_id = T.team_api_id
    LEFT JOIN
        Team TM ON M.away_team_api_id = TM.team_api_id
),
match_score AS (
    SELECT
        id,
        team,
        Winning_match
    FROM (
        SELECT
            id,
            home_team AS team,
            CASE WHEN home_team_goal > away_team_goal THEN 1 ELSE 0 END AS Winning_match
        FROM
            match_view
        UNION ALL
        SELECT
            id,
            away_team AS team,
            CASE WHEN away_team_goal > home_team_goal THEN 1 ELSE 0 END AS Winning_match
        FROM
            match_view
    )
)
SELECT
    MV.league,
    M.team,
    COUNT(CASE WHEN M.Winning_match = 1 THEN 1 END) AS wins
FROM
    match_score M
JOIN
    match_view MV ON M.id = MV.id
GROUP BY
    MV.league,
    M.team
ORDER BY
    MV.league,
    wins DESC;