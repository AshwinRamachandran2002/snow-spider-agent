WITH players_with_15_points AS (
    SELECT
        P."player_id",
        P."team_id"
    FROM
        "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_PBP_SR" P
    WHERE
        P."season" BETWEEN 2010 AND 2018
        AND P."period" = 2
        AND P."points_scored" IS NOT NULL
    GROUP BY
        P."player_id",
        P."team_id"
    HAVING
        SUM(P."points_scored") >= 15
),
player_counts AS (
    SELECT
        PW."team_id",
        COUNT(DISTINCT PW."player_id") AS "num_players"
    FROM
        players_with_15_points PW
    GROUP BY
        PW."team_id"
),
top_teams AS (
    SELECT
        PC."team_id"
    FROM
        player_counts PC
    ORDER BY
        PC."num_players" DESC
    LIMIT 5
),
top_teams_info AS (
    SELECT
        T."id" AS "team_id",
        T."market",
        T."kaggle_team_id"
    FROM
        "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_TEAMS" T
        JOIN top_teams TT ON T."id" = TT."team_id"
    WHERE
        T."kaggle_team_id" IS NOT NULL
),
top_kaggle_ids AS (
    SELECT DISTINCT TTI."kaggle_team_id"
    FROM top_teams_info TTI
)
SELECT
    G."season",
    G."round",
    G."game_date",
    G."win_market",
    G."win_name",
    G."win_seed",
    G."win_pts",
    G."lose_market",
    G."lose_name",
    G."lose_seed",
    G."lose_pts",
    COALESCE(G."num_ot", 0) AS "num_ot"
FROM
    "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_HISTORICAL_TOURNAMENT_GAMES" G
WHERE
    G."season" BETWEEN 2010 AND 2018
    AND (
        G."win_kaggle_team_id" IN (SELECT "kaggle_team_id" FROM top_kaggle_ids)
        OR G."lose_kaggle_team_id" IN (SELECT "kaggle_team_id" FROM top_kaggle_ids)
    )
ORDER BY
    G."season" ASC NULLS LAST,
    G."game_date" ASC NULLS LAST,
    G."round" ASC NULLS LAST;