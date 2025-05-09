WITH match_points AS (
    /* 1.  Give every team points for every match (home and away)              */
    SELECT
        season,
        league_id,
        country_id,
        home_team_api_id                    AS team_api_id,
        CASE
            WHEN home_team_goal  > away_team_goal THEN 3
            WHEN home_team_goal  = away_team_goal THEN 1
            ELSE 0
        END                                 AS pts
    FROM   "Match"

    UNION ALL

    SELECT
        season,
        league_id,
        country_id,
        away_team_api_id                    AS team_api_id,
        CASE
            WHEN away_team_goal  > home_team_goal THEN 3
            WHEN away_team_goal  = home_team_goal THEN 1
            ELSE 0
        END                                 AS pts
    FROM   "Match"
),

season_team_points AS (
    /* 2.  Aggregate the points per season‑league‑team                         */
    SELECT
        season,
        league_id,
        country_id,
        team_api_id,
        SUM(pts)           AS total_points
    FROM   match_points
    GROUP  BY season, league_id, country_id, team_api_id
),

season_champ_ranked AS (
    /* 3.  Rank teams by points inside every season & league                   */
    SELECT
        stp.*,
        RANK() OVER (PARTITION BY season, league_id
                     ORDER BY total_points DESC, team_api_id) AS rnk
    FROM   season_team_points stp
),

champions AS (
    /* 4.  Keep only the top‑ranked (champion) team for each season & league   */
    SELECT
        season,
        league_id,
        country_id,
        team_api_id,
        total_points
    FROM   season_champ_ranked
    WHERE  rnk = 1
)

/* 5.  Bring in names of the team, league and country                          */
SELECT
    t.team_long_name      AS team_name,
    l.name                AS league_name,
    c.name                AS country_name,
    ch.season,
    ch.total_points
FROM   champions          ch
JOIN   "Team"    t ON t.team_api_id = ch.team_api_id
JOIN   "League"  l ON l.id          = ch.league_id
JOIN   "Country" c ON c.id          = ch.country_id
ORDER  BY ch.season,
          country_name,
          league_name;