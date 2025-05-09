WITH batsman_totals AS (
    SELECT  m."season_id",
            bb."striker"                 AS "player_id",
            SUM(bs."runs_scored")        AS "total_runs"
    FROM    "ball_by_ball"   AS bb
    JOIN    "batsman_scored" AS bs
           ON  bb."match_id" = bs."match_id"
          AND bb."over_id"  = bs."over_id"
          AND bb."ball_id"  = bs."ball_id"
    JOIN    "match"          AS m
           ON  m."match_id"  = bb."match_id"
    GROUP BY m."season_id", bb."striker"
),
ranked_batsmen AS (                 -- top-3 per season, ties→smaller player_id
    SELECT  bt.*,
            ROW_NUMBER() OVER (PARTITION BY bt."season_id"
                               ORDER BY bt."total_runs" DESC,
                                        bt."player_id") AS "rank_pos"
    FROM    batsman_totals bt
),
bowler_totals AS (
    SELECT  m."season_id",
            bb."bowler"                  AS "player_id",
            COUNT(*)                     AS "wickets"
    FROM    "ball_by_ball" AS bb
    JOIN    "wicket_taken" AS wt
           ON  bb."match_id" = wt."match_id"
          AND bb."over_id"  = wt."over_id"
          AND bb."ball_id"  = wt."ball_id"
    JOIN    "match"        AS m
           ON  m."match_id" = bb."match_id"
    WHERE   wt."kind_out" NOT IN ('run out','hit wicket','retired hurt')
    GROUP BY m."season_id", bb."bowler"
),
ranked_bowlers AS (                 -- top-3 per season, ties→smaller player_id
    SELECT  bw.*,
            ROW_NUMBER() OVER (PARTITION BY bw."season_id"
                               ORDER BY bw."wickets" DESC,
                                        bw."player_id") AS "rank_pos"
    FROM    bowler_totals bw
),
paired AS (                         -- match batsman-rank with bowler-rank
    SELECT  b."season_id",
            b."rank_pos",
            b."player_id"  AS "batsman_id",
            b."total_runs",
            w."player_id"  AS "bowler_id",
            w."wickets"
    FROM    ranked_batsmen  b
    JOIN    ranked_bowlers  w
           ON  b."season_id" = w."season_id"
          AND b."rank_pos"  = w."rank_pos"
    WHERE   b."rank_pos" <= 3            -- only top-3
)
SELECT  p."season_id",
        p."rank_pos",
        pb."player_name" AS "batsman_name",
        p."total_runs",
        pw."player_name" AS "bowler_name",
        p."wickets"
FROM    paired   p
JOIN    "player" pb ON pb."player_id" = p."batsman_id"
JOIN    "player" pw ON pw."player_id" = p."bowler_id"
ORDER BY p."season_id", p."rank_pos";