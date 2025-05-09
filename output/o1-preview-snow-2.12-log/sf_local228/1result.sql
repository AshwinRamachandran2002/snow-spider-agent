WITH Top_Batsmen AS (
    SELECT *
    FROM (
        SELECT
            m."season_id",
            b."striker" AS "player_id",
            SUM(bs."runs_scored") AS "batsman_runs",
            RANK() OVER (
                PARTITION BY m."season_id"
                ORDER BY SUM(bs."runs_scored") DESC NULLS LAST, b."striker" ASC
            ) AS "position"
        FROM
            "IPL"."IPL"."BATSMAN_SCORED" bs
        JOIN
            "IPL"."IPL"."BALL_BY_BALL" b
        ON
            bs."match_id" = b."match_id" AND
            bs."over_id" = b."over_id" AND
            bs."ball_id" = b."ball_id" AND
            bs."innings_no" = b."innings_no"
        JOIN
            "IPL"."IPL"."MATCH" m
        ON
            bs."match_id" = m."match_id"
        GROUP BY
            m."season_id", b."striker"
    ) bat_ranks
    WHERE
        "position" <= 3
),
Top_Bowlers AS (
    SELECT *
    FROM (
        SELECT
            m."season_id",
            b."bowler" AS "player_id",
            COUNT(*) AS "bowler_wickets",
            RANK() OVER (
                PARTITION BY m."season_id"
                ORDER BY COUNT(*) DESC NULLS LAST, b."bowler" ASC
            ) AS "position"
        FROM
            "IPL"."IPL"."WICKET_TAKEN" w
        JOIN
            "IPL"."IPL"."BALL_BY_BALL" b
        ON
            w."match_id" = b."match_id" AND
            w."over_id" = b."over_id" AND
            w."ball_id" = b."ball_id" AND
            w."innings_no" = b."innings_no"
        JOIN
            "IPL"."IPL"."MATCH" m
        ON
            w."match_id" = m."match_id"
        WHERE
            w."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
        GROUP BY
            m."season_id", b."bowler"
    ) bowl_ranks
    WHERE
        "position" <= 3
)
SELECT
    t_bat."season_id",
    t_bat."position",
    p_bat."player_name" AS "batsman_name",
    t_bat."batsman_runs",
    p_bowl."player_name" AS "bowler_name",
    t_bowl."bowler_wickets"
FROM
    Top_Batsmen t_bat
JOIN
    Top_Bowlers t_bowl
ON
    t_bat."season_id" = t_bowl."season_id" AND
    t_bat."position" = t_bowl."position"
JOIN
    "IPL"."IPL"."PLAYER" p_bat
ON
    t_bat."player_id" = p_bat."player_id"
JOIN
    "IPL"."IPL"."PLAYER" p_bowl
ON
    t_bowl."player_id" = p_bowl."player_id"
ORDER BY
    t_bat."season_id" ASC,
    t_bat."position" ASC;