SELECT
    wins."league_id",
    l."name" AS league_name,
    t."team_api_id" AS team_id,
    t."team_long_name",
    wins."total_wins" AS wins
FROM
    (
        SELECT
            "league_id",
            "team_id",
            COUNT(*) AS "total_wins"
        FROM
            (
                SELECT
                    m."league_id",
                    m."home_team_api_id" AS "team_id"
                FROM
                    "Match" m
                WHERE
                    m."home_team_goal" > m."away_team_goal"
                UNION ALL
                SELECT
                    m."league_id",
                    m."away_team_api_id" AS "team_id"
                FROM
                    "Match" m
                WHERE
                    m."away_team_goal" > m."home_team_goal"
            ) AS all_wins
        GROUP BY
            "league_id",
            "team_id"
    ) AS wins
    INNER JOIN (
        SELECT
            "league_id",
            MIN("total_wins") AS "min_wins"
        FROM
            (
                SELECT
                    "league_id",
                    "team_id",
                    COUNT(*) AS "total_wins"
                FROM
                    (
                        SELECT
                            m."league_id",
                            m."home_team_api_id" AS "team_id"
                        FROM
                            "Match" m
                        WHERE
                            m."home_team_goal" > m."away_team_goal"
                        UNION ALL
                        SELECT
                            m."league_id",
                            m."away_team_api_id" AS "team_id"
                        FROM
                            "Match" m
                        WHERE
                            m."away_team_goal" > m."home_team_goal"
                        ) AS all_wins_inner
                    GROUP BY
                        "league_id",
                        "team_id"
                )
            GROUP BY
                "league_id"
    ) AS min_wins_per_league ON wins."league_id" = min_wins_per_league."league_id" AND wins."total_wins" = min_wins_per_league."min_wins"
    JOIN "Team" t ON t."team_api_id" = wins."team_id"
    JOIN "League" l ON l."id" = wins."league_id"
ORDER BY
    wins."league_id", t."team_long_name";