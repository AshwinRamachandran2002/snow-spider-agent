WITH points_per_side AS (
    /* 1.  Give every team in every match a points value               */
    SELECT 
           m.season,
           m.league_id,
           m.home_team_api_id          AS team_api_id,
           CASE WHEN m.home_team_goal > m.away_team_goal THEN 3
                WHEN m.home_team_goal = m.away_team_goal THEN 1
                ELSE 0
           END                         AS pts
    FROM   Match m
    
    UNION ALL
    
    SELECT 
           m.season,
           m.league_id,
           m.away_team_api_id,
           CASE WHEN m.away_team_goal > m.home_team_goal THEN 3
                WHEN m.away_team_goal = m.home_team_goal THEN 1
                ELSE 0
           END
    FROM   Match m
),
season_totals AS (
    /* 2.  Total points per (season, league, team)                     */
    SELECT  season,
            league_id,
            team_api_id,
            SUM(pts)                   AS total_points
    FROM    points_per_side
    GROUP BY season, league_id, team_api_id
),
max_per_league AS (
    /* 3.  Best points tally inside every (season, league)             */
    SELECT  season,
            league_id,
            MAX(total_points)          AS max_points
    FROM    season_totals
    GROUP BY season, league_id
)
SELECT  st.season,
        c.name                        AS country,
        l.name                        AS league,
        t.team_long_name              AS champion_team,
        st.total_points               AS total_points
FROM        season_totals   st
INNER JOIN  max_per_league  mp
           ON  st.season      = mp.season
           AND st.league_id   = mp.league_id
           AND st.total_points= mp.max_points
INNER JOIN  League           l  ON l.id          = st.league_id
INNER JOIN  Country          c  ON c.id          = l.country_id
INNER JOIN  Team             t  ON t.team_api_id = st.team_api_id
ORDER BY st.season,
         c.name,
         l.name,
         t.team_long_name;