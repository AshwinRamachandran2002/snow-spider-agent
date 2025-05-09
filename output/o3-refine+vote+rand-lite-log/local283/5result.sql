WITH match_points AS (          -- 1.  Points earned by every team in every match
    SELECT
        "season",
        "league_id",
        "country_id",
        "home_team_api_id" AS team_api_id,
        CASE
            WHEN home_team_goal  > away_team_goal THEN 3
            WHEN home_team_goal  = away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM "Match"

    UNION ALL

    SELECT
        "season",
        "league_id",
        "country_id",
        "away_team_api_id" AS team_api_id,
        CASE
            WHEN away_team_goal  > home_team_goal THEN 3
            WHEN away_team_goal  = home_team_goal THEN 1
            ELSE 0
        END AS points
    FROM "Match"
),

season_team_points AS (         -- 2.  Total points of every team per season & league
    SELECT
        season,
        league_id,
        country_id,
        team_api_id,
        SUM(points) AS total_points
    FROM match_points
    GROUP BY season, league_id, country_id, team_api_id
),

season_league_max AS (          -- 3.  Max points reached in every season & league
    SELECT
        season,
        league_id,
        MAX(total_points) AS max_points
    FROM season_team_points
    GROUP BY season, league_id
),

champions AS (                  -- 4.  Team(s) that reached the max ⇒ champion(s)
    SELECT
        stp.season,
        stp.league_id,
        stp.country_id,
        stp.team_api_id,
        stp.total_points
    FROM season_team_points AS stp
    JOIN season_league_max  AS slm
         ON  stp.season      = slm.season
         AND stp.league_id   = slm.league_id
         AND stp.total_points = slm.max_points
)

-- 5.  Attach descriptive names and return the champions
SELECT
    c.season                                  AS season,
    t.team_long_name                          AS champion_team,
    l.name                                    AS league,
    co.name                                   AS country,
    c.total_points                            AS total_points
FROM champions AS c
JOIN "Team"    AS t   ON t.team_api_id = c.team_api_id
JOIN "League"  AS l   ON l.id          = c.league_id
JOIN "Country" AS co  ON co.id         = c.country_id
ORDER BY
    c.season,
    co.name,
    l.name,
    t.team_long_name;