WITH Team_Points AS (
    SELECT
        M.season,
        M.league_id,
        M.country_id,
        M.home_team_api_id AS team_api_id,
        CASE
            WHEN M.home_team_goal > M.away_team_goal THEN 3
            WHEN M.home_team_goal = M.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM
        "Match" M
    UNION ALL
    SELECT
        M.season,
        M.league_id,
        M.country_id,
        M.away_team_api_id AS team_api_id,
        CASE
            WHEN M.home_team_goal < M.away_team_goal THEN 3
            WHEN M.home_team_goal = M.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM
        "Match" M
),
Team_Season_Points AS (
    SELECT
        TP.season,
        TP.team_api_id,
        SUM(TP.points) AS total_points
    FROM
        Team_Points TP
    GROUP BY
        TP.season,
        TP.team_api_id
),
Season_Max_Points AS (
    SELECT
        season,
        MAX(total_points) AS max_points
    FROM
        Team_Season_Points
    GROUP BY
        season
),
Team_League_Match_Count AS (
    SELECT
        season,
        team_api_id,
        league_id,
        country_id,
        COUNT(*) AS match_count
    FROM
        Team_Points
    GROUP BY
        season,
        team_api_id,
        league_id,
        country_id
),
Team_Main_League AS (
    SELECT
        TLM1.season,
        TLM1.team_api_id,
        TLM1.league_id,
        TLM1.country_id
    FROM
        Team_League_Match_Count TLM1
    JOIN (
        SELECT
            season,
            team_api_id,
            MAX(match_count) AS max_match_count
        FROM
            Team_League_Match_Count
        GROUP BY
            season,
            team_api_id
    ) TLM2 ON
        TLM1.season = TLM2.season AND
        TLM1.team_api_id = TLM2.team_api_id AND
        TLM1.match_count = TLM2.max_match_count
    GROUP BY
        TLM1.season,
        TLM1.team_api_id
)
SELECT
    TSP.season AS Season,
    T.team_long_name AS Champion_Team_Name,
    L.name AS League,
    C.name AS Country,
    TSP.total_points AS Total_Points
FROM
    Team_Season_Points TSP
JOIN
    Season_Max_Points SMP ON TSP.season = SMP.season AND TSP.total_points = SMP.max_points
JOIN
    Team_Main_League TML ON TML.season = TSP.season AND TML.team_api_id = TSP.team_api_id
JOIN
    "Team" T ON T.team_api_id = TSP.team_api_id
JOIN
    "League" L ON L.id = TML.league_id
JOIN
    "Country" C ON C.id = TML.country_id
ORDER BY
    TSP.season;