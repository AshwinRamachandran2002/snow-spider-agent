WITH outcome AS (
    /* matches with a clear winner */
    SELECT  id,
            CASE 
                WHEN home_team_goal > away_team_goal THEN 'home'
                WHEN away_team_goal > home_team_goal THEN 'away'
            END                        AS winner_side
    FROM   Match
    WHERE  home_team_goal <> away_team_goal
),
player_occurrences AS (
    /* every player that actually appeared in those matches,
       marked with the side (home/away) he played for          */
    SELECT id, home_player_1 AS player_api_id, 'home' AS side FROM Match UNION ALL
    SELECT id, home_player_2, 'home' FROM Match UNION ALL
    SELECT id, home_player_3, 'home' FROM Match UNION ALL
    SELECT id, home_player_4, 'home' FROM Match UNION ALL
    SELECT id, home_player_5, 'home' FROM Match UNION ALL
    SELECT id, home_player_6, 'home' FROM Match UNION ALL
    SELECT id, home_player_7, 'home' FROM Match UNION ALL
    SELECT id, home_player_8, 'home' FROM Match UNION ALL
    SELECT id, home_player_9, 'home' FROM Match UNION ALL
    SELECT id, home_player_10,'home' FROM Match UNION ALL
    SELECT id, home_player_11,'home' FROM Match UNION ALL
    SELECT id, away_player_1,'away' FROM Match UNION ALL
    SELECT id, away_player_2,'away' FROM Match UNION ALL
    SELECT id, away_player_3,'away' FROM Match UNION ALL
    SELECT id, away_player_4,'away' FROM Match UNION ALL
    SELECT id, away_player_5,'away' FROM Match UNION ALL
    SELECT id, away_player_6,'away' FROM Match UNION ALL
    SELECT id, away_player_7,'away' FROM Match UNION ALL
    SELECT id, away_player_8,'away' FROM Match UNION ALL
    SELECT id, away_player_9,'away' FROM Match UNION ALL
    SELECT id, away_player_10,'away' FROM Match UNION ALL
    SELECT id, away_player_11,'away' FROM Match
),
player_results AS (
    /* tag each appearance as win or loss */
    SELECT  po.player_api_id,
            CASE 
                WHEN o.winner_side = po.side THEN 'win'
                ELSE 'loss'
            END AS result
    FROM   player_occurrences po
    JOIN   outcome o ON o.id = po.id
    WHERE  po.player_api_id IS NOT NULL          -- exclude empty slots
),
aggregated AS (
    /* total wins and losses for every player */
    SELECT  player_api_id,
            SUM(CASE WHEN result = 'win'  THEN 1 ELSE 0 END) AS wins,
            SUM(CASE WHEN result = 'loss' THEN 1 ELSE 0 END) AS losses
    FROM    player_results
    GROUP BY player_api_id
),
top_winner AS (
    SELECT player_api_id, wins
    FROM   aggregated
    ORDER  BY wins DESC, player_api_id
    LIMIT  1
),
top_loser AS (
    SELECT player_api_id, losses
    FROM   aggregated
    ORDER  BY losses DESC, player_api_id
    LIMIT  1
)
SELECT 'most_wins'  AS category,
       p.player_name,
       t.wins        AS match_count
FROM   top_winner t
JOIN   Player p ON p.player_api_id = t.player_api_id

UNION ALL

SELECT 'most_losses',
       p.player_name,
       t.losses
FROM   top_loser t
JOIN   Player p ON p.player_api_id = t.player_api_id;