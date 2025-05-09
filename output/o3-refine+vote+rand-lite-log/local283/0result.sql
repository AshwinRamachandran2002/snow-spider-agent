WITH point_events AS (
    /* 1 point record for every team‑match (home or away) */
    SELECT
        season,
        league_id,
        country_id,
        home_team_api_id               AS team_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END                             AS pts
    FROM Match

    UNION ALL

    SELECT
        season,
        league_id,
        country_id,
        away_team_api_id,
        CASE
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END
    FROM Match
),
team_season_points AS (
    /* total points per team & season */
    SELECT
        season,
        team_id,
        league_id,
        country_id,
        SUM(pts) AS total_points
    FROM point_events
    GROUP BY season, team_id
),
champions AS (
    /* pick the season champion (highest points) */
    SELECT
        season,
        team_id,
        league_id,
        country_id,
        total_points,
        ROW_NUMBER() OVER (
            PARTITION BY season
            ORDER BY total_points DESC, team_id
        ) AS rn
    FROM team_season_points
)
SELECT
    T.team_long_name  AS team_name,
    L.name            AS league_name,
    C.name            AS country_name,
    ch.total_points   AS total_points
FROM champions ch
JOIN Team    T ON T.team_api_id = ch.team_id
JOIN League  L ON L.id          = ch.league_id
JOIN Country C ON C.id          = ch.country_id
WHERE ch.rn = 1
ORDER BY ch.season;