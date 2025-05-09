WITH all_players AS (
    -- Home team players
    SELECT
        m."match_api_id",
        m."home_team_api_id" AS "team_api_id",
        m."home_player_1" AS "player_api_id",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END AS "winner_team_api_id"
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_1" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_2",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_2" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_3",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_3" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_4",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_4" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_5",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_5" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_6",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_6" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_7",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_7" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_8",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_8" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_9",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_9" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_10",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_10" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."home_team_api_id",
        m."home_player_11",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."home_player_11" IS NOT NULL

    UNION ALL

    -- Away team players
    SELECT
        m."match_api_id",
        m."away_team_api_id" AS "team_api_id",
        m."away_player_1" AS "player_api_id",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END AS "winner_team_api_id"
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_1" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_2",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_2" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_3",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_3" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_4",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_4" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_5",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_5" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_6",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_6" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_7",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_7" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_8",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_8" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_9",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_9" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_10",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_10" IS NOT NULL

    UNION ALL

    SELECT
        m."match_api_id",
        m."away_team_api_id",
        m."away_player_11",
        m."home_team_goal",
        m."away_team_goal",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."home_team_goal" < m."away_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END AS "winner_team_api_id"
    FROM EU_SOCCER.EU_SOCCER."MATCH" m
    WHERE m."away_player_11" IS NOT NULL
),
player_wins AS (
    SELECT
        "player_api_id",
        COUNT(*) AS "matches_played",
        COUNT(CASE WHEN "team_api_id" = "winner_team_api_id" THEN 1 END) AS "wins"
    FROM all_players
    WHERE "player_api_id" IS NOT NULL AND "team_api_id" IS NOT NULL AND "winner_team_api_id" IS NOT NULL
    GROUP BY "player_api_id"
),
most_wins AS (
    SELECT "player_api_id", "wins"
    FROM player_wins
    ORDER BY "wins" DESC NULLS LAST
    LIMIT 1
)
SELECT
    p."player_name",
    mw."wins" AS "number_of_wins"
FROM most_wins mw
JOIN EU_SOCCER.EU_SOCCER."PLAYER" p
  ON mw."player_api_id" = p."player_api_id";