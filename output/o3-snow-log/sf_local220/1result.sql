WITH
/* 1.  home-side players together with their team/opponent goals */
home_players AS (
    SELECT "match_api_id",
           "home_team_goal"        AS team_goal,
           "away_team_goal"        AS opp_goal,
           CAST("home_player_1"  AS NUMBER) AS player_api_id  FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_2"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_3"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_4"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_5"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_6"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_7"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_8"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_9"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_10" AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","home_team_goal","away_team_goal",CAST("home_player_11" AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH
),
/* 2.  away-side players together with their team/opponent goals */
away_players AS (
    SELECT "match_api_id",
           "away_team_goal"        AS team_goal,
           "home_team_goal"        AS opp_goal,
           CAST("away_player_1"  AS NUMBER) AS player_api_id  FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_2"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_3"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_4"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_5"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_6"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_7"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_8"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_9"  AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_10" AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH UNION ALL
    SELECT "match_api_id","away_team_goal","home_team_goal",CAST("away_player_11" AS NUMBER) FROM EU_SOCCER.EU_SOCCER.MATCH
),
/* 3. combine both sides */
all_players AS (
    SELECT * FROM home_players
    UNION ALL
    SELECT * FROM away_players
),
/* 4. assign outcome, ignore NULL player slots */
player_outcomes AS (
    SELECT
        player_api_id,
        CASE
            WHEN team_goal > opp_goal THEN 'win'
            WHEN team_goal < opp_goal THEN 'loss'
            ELSE 'draw'
        END AS outcome
    FROM all_players
    WHERE player_api_id IS NOT NULL
),
/* 5. count wins and losses per player */
player_counts AS (
    SELECT
        player_api_id,
        outcome,
        COUNT(*) AS match_count
    FROM player_outcomes
    WHERE outcome IN ('win','loss')
    GROUP BY player_api_id, outcome
),
/* 6. player with most wins */
top_winner AS (
    SELECT player_api_id, match_count AS win_matches
    FROM   player_counts
    WHERE  outcome = 'win'
    ORDER  BY win_matches DESC NULLS LAST
    LIMIT 1
),
/* 7. player with most losses */
top_loser AS (
    SELECT player_api_id, match_count AS loss_matches
    FROM   player_counts
    WHERE  outcome = 'loss'
    ORDER  BY loss_matches DESC NULLS LAST
    LIMIT 1
)
/* 8. final output with player names */
SELECT 'Most_Wins' AS result_type,
       p."player_name",
       t.win_matches AS match_count
FROM   top_winner t
JOIN   EU_SOCCER.EU_SOCCER.PLAYER p
       ON p."player_api_id" = t.player_api_id

UNION ALL

SELECT 'Most_Losses',
       p."player_name",
       t.loss_matches
FROM   top_loser t
JOIN   EU_SOCCER.EU_SOCCER.PLAYER p
       ON p."player_api_id" = t.player_api_id
ORDER BY result_type;