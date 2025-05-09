WITH points AS (
    /* 1.  Convert every match result into points for the side involved */
    SELECT 
        season,
        league_id,
        home_team_api_id          AS team_api_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END                       AS pts
    FROM "Match"

    UNION ALL

    SELECT
        season,
        league_id,
        away_team_api_id,
        CASE
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END
    FROM "Match"
),
totals AS (
    /* 2.  Aggregate points per team within every league-season */
    SELECT
        season,
        league_id,
        team_api_id,
        SUM(pts) AS total_points
    FROM points
    GROUP BY season, league_id, team_api_id
),
max_per_league AS (
    /* 3.  Identify the highest points tally for each league-season */
    SELECT
        season,
        league_id,
        MAX(total_points) AS max_points
    FROM totals
    GROUP BY season, league_id
),
champions AS (
    /* 4.  Keep only the team(s) whose total equals that maximum */
    SELECT
        t.season,
        t.league_id,
        t.team_api_id,
        t.total_points
    FROM totals t
    JOIN max_per_league m
      ON t.season      = m.season
     AND t.league_id   = m.league_id
     AND t.total_points = m.max_points
)
SELECT
    c.name            AS country,
    l.name            AS league,
    tm.team_long_name AS team,
    ch.total_points,
    ch.season
FROM champions   AS ch
JOIN "League"    AS l  ON ch.league_id   = l.id
JOIN "Country"   AS c  ON l.country_id   = c.id
JOIN "Team"      AS tm ON ch.team_api_id = tm.team_api_id
ORDER BY ch.season,
         country,
         league,
         team;