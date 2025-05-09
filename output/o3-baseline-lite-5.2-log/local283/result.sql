WITH match_points AS (
    /* 1. Give every team the points it earned in each match */
    SELECT
        season,
        league_id,
        home_team_api_id AS team_api_id,
        CASE 
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM "Match"

    UNION ALL

    SELECT
        season,
        league_id,
        away_team_api_id AS team_api_id,
        CASE 
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END AS points
    FROM "Match"
),
season_team_points AS (
    /* 2. Total points for every team within each league‑season */
    SELECT
        season,
        league_id,
        team_api_id,
        SUM(points) AS total_points
    FROM match_points
    GROUP BY season, league_id, team_api_id
),
season_league_max AS (
    /* 3. Best point tally in every league‑season */
    SELECT
        season,
        league_id,
        MAX(total_points) AS max_points
    FROM season_team_points
    GROUP BY season, league_id
),
champions AS (
    /* 4. Pick the team(s) that reached the best tally (handles ties) */
    SELECT
        stp.season,
        stp.league_id,
        stp.team_api_id,
        stp.total_points
    FROM season_team_points stp
    JOIN season_league_max slm
      ON stp.season      = slm.season
     AND stp.league_id   = slm.league_id
     AND stp.total_points = slm.max_points
)
SELECT
    c.name                      AS country,
    l.name                      AS league,
    t.team_long_name            AS champion_team,
    ch.season,
    ch.total_points             AS points
FROM champions ch
JOIN League  l ON ch.league_id   = l.id
JOIN Country c ON l.country_id   = c.id
JOIN Team    t ON ch.team_api_id = t.team_api_id
ORDER BY
    ch.season,
    l.name,
    champion_team;