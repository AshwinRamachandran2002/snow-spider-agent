WITH bats AS (
    /* Season-wise total runs for every batsman + rank */
    SELECT  m."season_id",
            bbb."striker"                       AS "player_id",
            SUM(bs."runs_scored")               AS "total_runs",
            DENSE_RANK() OVER (
                PARTITION BY m."season_id"
                ORDER BY SUM(bs."runs_scored") DESC,
                         bbb."striker"
            )                                   AS "rk"
    FROM    "ball_by_ball"  AS bbb
    JOIN    "batsman_scored" AS bs
           ON bbb."match_id" = bs."match_id"
          AND bbb."over_id"  = bs."over_id"
          AND bbb."ball_id"  = bs."ball_id"
    JOIN    "match" AS m
           ON m."match_id" = bbb."match_id"
    GROUP BY m."season_id", bbb."striker"
), bowl AS (
    /* Season-wise wickets for every bowler (dismissal filter) + rank */
    SELECT  m."season_id",
            bbb."bowler"                        AS "player_id",
            COUNT(*)                            AS "wickets",
            DENSE_RANK() OVER (
                PARTITION BY m."season_id"
                ORDER BY COUNT(*) DESC,
                         bbb."bowler"
            )                                   AS "rk"
    FROM    "ball_by_ball" AS bbb
    JOIN    "wicket_taken" AS wt
           ON bbb."match_id" = wt."match_id"
          AND bbb."over_id"  = wt."over_id"
          AND bbb."ball_id"  = wt."ball_id"
    JOIN    "match" AS m
           ON m."match_id" = bbb."match_id"
    WHERE   wt."kind_out" NOT IN ('run out','hit wicket','retired hurt')
    GROUP BY m."season_id", bbb."bowler"
)
SELECT  bats."season_id",
        bats."player_id"     AS "batsman_id",
        p1."player_name"     AS "batsman_name",
        bats."total_runs",
        bowl."player_id"     AS "bowler_id",
        p2."player_name"     AS "bowler_name",
        bowl."wickets"
FROM    bats
JOIN    bowl
      ON bowl."season_id" = bats."season_id"
     AND bowl."rk"        = bats."rk"          -- pair 1-1, 2-2, 3-3
JOIN    "player" AS p1
      ON p1."player_id" = bats."player_id"
JOIN    "player" AS p2
      ON p2."player_id" = bowl."player_id"
WHERE   bats."rk" <= 3
ORDER BY bats."season_id", bats."rk";