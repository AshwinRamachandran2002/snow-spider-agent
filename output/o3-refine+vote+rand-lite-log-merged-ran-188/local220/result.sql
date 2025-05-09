WITH non_draw_matches AS (
    /* keep only games that had a winner */
    SELECT  id,
            home_team_goal ,
            away_team_goal ,
            CASE WHEN home_team_goal > away_team_goal THEN 'home'
                 ELSE 'away'
            END             AS winner_side
    FROM   Match
    WHERE  home_team_goal <> away_team_goal
),
player_outcomes AS (
    /* build one row per (player, match) telling if it was a win or a loss   */
    /* ---------------- HOME TEAM ---------------- */
    SELECT m.home_player_1 AS player_api_id,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END AS win,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END AS loss
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_1 IS NOT NULL
    UNION ALL
    SELECT m.home_player_2, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_2 IS NOT NULL
    UNION ALL
    SELECT m.home_player_3, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_3 IS NOT NULL
    UNION ALL
    SELECT m.home_player_4, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_4 IS NOT NULL
    UNION ALL
    SELECT m.home_player_5, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_5 IS NOT NULL
    UNION ALL
    SELECT m.home_player_6, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_6 IS NOT NULL
    UNION ALL
    SELECT m.home_player_7, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_7 IS NOT NULL
    UNION ALL
    SELECT m.home_player_8, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_8 IS NOT NULL
    UNION ALL
    SELECT m.home_player_9, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_9 IS NOT NULL
    UNION ALL
    SELECT m.home_player_10, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_10 IS NOT NULL
    UNION ALL
    SELECT m.home_player_11, CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.home_player_11 IS NOT NULL
    /* ---------------- AWAY TEAM ---------------- */
    UNION ALL
    SELECT m.away_player_1, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_1 IS NOT NULL
    UNION ALL
    SELECT m.away_player_2, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_2 IS NOT NULL
    UNION ALL
    SELECT m.away_player_3, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_3 IS NOT NULL
    UNION ALL
    SELECT m.away_player_4, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_4 IS NOT NULL
    UNION ALL
    SELECT m.away_player_5, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_5 IS NOT NULL
    UNION ALL
    SELECT m.away_player_6, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_6 IS NOT NULL
    UNION ALL
    SELECT m.away_player_7, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_7 IS NOT NULL
    UNION ALL
    SELECT m.away_player_8, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_8 IS NOT NULL
    UNION ALL
    SELECT m.away_player_9, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_9 IS NOT NULL
    UNION ALL
    SELECT m.away_player_10, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_10 IS NOT NULL
    UNION ALL
    SELECT m.away_player_11, CASE WHEN nd.winner_side='away' THEN 1 ELSE 0 END,
           CASE WHEN nd.winner_side='home' THEN 1 ELSE 0 END
    FROM   Match m JOIN non_draw_matches nd ON nd.id=m.id
    WHERE  m.away_player_11 IS NOT NULL
),
player_stats AS (
    /* total wins & losses for every player */
    SELECT  player_api_id,
            SUM(win)  AS wins,
            SUM(loss) AS losses
    FROM    player_outcomes
    GROUP BY player_api_id
),
max_vals AS (
    SELECT MAX(wins)   AS max_wins,
           MAX(losses) AS max_losses
    FROM   player_stats
)
/* final answer: players with most wins and most losses */
SELECT 'most_wins'  AS category,
       p.player_name,
       ps.wins       AS match_count
FROM   player_stats ps, max_vals mv
JOIN   Player p ON p.player_api_id = ps.player_api_id
WHERE  ps.wins = mv.max_wins

UNION ALL

SELECT 'most_losses',
       p.player_name,
       ps.losses
FROM   player_stats ps, max_vals mv
JOIN   Player p ON p.player_api_id = ps.player_api_id
WHERE  ps.losses = mv.max_losses

ORDER BY category;