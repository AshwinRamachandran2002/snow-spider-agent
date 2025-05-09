WITH match_player AS (

    /* ----------  HOME PLAYERS  ---------- */
    SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home' AS side, m."home_player_1"  AS player_api_id
    FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_1"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_2"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_2"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_3"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_3"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_4"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_4"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_5"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_5"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_6"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_6"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_7"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_7"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_8"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_8"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_9"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_9"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_10" FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_10" IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'home', m."home_player_11" FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."home_player_11" IS NOT NULL

    /* ----------  AWAY PLAYERS  ---------- */
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_1"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_1"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_2"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_2"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_3"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_3"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_4"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_4"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_5"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_5"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_6"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_6"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_7"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_7"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_8"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_8"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_9"  FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_9"  IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_10" FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_10" IS NOT NULL
    UNION ALL SELECT m."match_api_id", m."home_team_goal", m."away_team_goal", 'away', m."away_player_11" FROM EU_SOCCER.EU_SOCCER.MATCH m WHERE m."away_player_11" IS NOT NULL
),

win_loss AS (
    SELECT
        player_api_id,
        CASE WHEN side = 'home' AND "home_team_goal" > "away_team_goal"
              OR side = 'away' AND "away_team_goal" > "home_team_goal" THEN 1 ELSE 0 END AS win_flag,
        CASE WHEN side = 'home' AND "home_team_goal" < "away_team_goal"
              OR side = 'away' AND "away_team_goal" < "home_team_goal" THEN 1 ELSE 0 END AS loss_flag
    FROM match_player
    WHERE "home_team_goal" <> "away_team_goal"          -- exclude draws
),

totals AS (
    SELECT
        player_api_id,
        SUM(win_flag)  AS wins,
        SUM(loss_flag) AS losses
    FROM win_loss
    GROUP BY player_api_id
),

max_wins AS (
    SELECT player_api_id, wins
    FROM totals
    ORDER BY wins DESC NULLS LAST
    LIMIT 1
),

max_losses AS (
    SELECT player_api_id, losses
    FROM totals
    ORDER BY losses DESC NULLS LAST
    LIMIT 1
)

SELECT
    'Most Winning Matches' AS metric,
    p."player_name",
    mw.wins AS match_count
FROM max_wins mw
JOIN EU_SOCCER.EU_SOCCER.PLAYER p
  ON p."player_api_id" = mw.player_api_id

UNION ALL

SELECT
    'Most Losing Matches',
    p."player_name",
    ml.losses
FROM max_losses ml
JOIN EU_SOCCER.EU_SOCCER.PLAYER p
  ON p."player_api_id" = ml.player_api_id;