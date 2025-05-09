WITH team_points AS (
    SELECT
        M.season,
        M.league_id,
        M.home_team_api_id AS team_api_id,
        CASE
            WHEN M.home_team_goal > M.away_team_goal THEN 3
            WHEN M.home_team_goal = M.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM
        "Match" M
    WHERE
        M.home_team_goal IS NOT NULL AND M.away_team_goal IS NOT NULL
    UNION ALL
    SELECT
        M.season,
        M.league_id,
        M.away_team_api_id AS team_api_id,
        CASE
            WHEN M.away_team_goal > M.home_team_goal THEN 3
            WHEN M.away_team_goal = M.home_team_goal THEN 1
            ELSE 0
        END AS points
    FROM
        "Match" M
    WHERE
        M.home_team_goal IS NOT NULL AND M.away_team_goal IS NOT NULL
),
team_totals AS (
    SELECT
        TP.season,
        TP.league_id,
        TP.team_api_id,
        SUM(TP.points) AS total_points
    FROM
        team_points TP
    GROUP BY
        TP.season,
        TP.league_id,
        TP.team_api_id
),
max_points AS (
    SELECT
        season,
        league_id,
        MAX(total_points) AS max_total_points
    FROM
        team_totals
    GROUP BY
        season,
        league_id
)
SELECT
    tt.season AS Season,
    T.team_long_name AS Team_Name,
    L.name AS League_Name,
    C.name AS Country_Name,
    tt.total_points AS Total_Points
FROM
    team_totals tt
JOIN max_points mp
    ON tt.season = mp.season
    AND tt.league_id = mp.league_id
    AND tt.total_points = mp.max_total_points
JOIN "Team" T
    ON tt.team_api_id = T.team_api_id
JOIN "League" L
    ON tt.league_id = L.id
JOIN "Country" C
    ON L.country_id = C.id
ORDER BY
    tt.season,
    L.name;