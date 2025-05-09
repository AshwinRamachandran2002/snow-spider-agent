WITH
/* -----------------------------------------------------------
1) Runs scored by every batsman in each season
----------------------------------------------------------- */
batsman_totals AS (
    SELECT
        m."season_id",
        bb."striker"                     AS "player_id",
        SUM(bs."runs_scored")            AS "total_runs"
    FROM   "match"          AS m
    JOIN   "ball_by_ball"   AS bb  ON m."match_id" = bb."match_id"
    JOIN   "batsman_scored" AS bs  ON bs."match_id" = bb."match_id"
                                   AND bs."over_id" = bb."over_id"
                                   AND bs."ball_id" = bb."ball_id"
    GROUP BY m."season_id", bb."striker"
),

/* -----------------------------------------------------------
2) Keep TOP-3 batsmen (tie-breaker: smaller player_id)
----------------------------------------------------------- */
top_batsmen AS (
    SELECT *
    FROM (
        SELECT
            bt."season_id",
            bt."player_id"               AS "batsman_id",
            bt."total_runs",
            ROW_NUMBER() OVER (PARTITION BY bt."season_id"
                               ORDER BY bt."total_runs" DESC, bt."player_id" ASC) AS pos
        FROM batsman_totals bt
    )
    WHERE pos <= 3
),

/* -----------------------------------------------------------
3) Wickets for every bowler in each season (dismissal filter)
----------------------------------------------------------- */
bowler_totals AS (
    SELECT
        m."season_id",
        bb."bowler"                     AS "player_id",
        COUNT(*)                        AS "total_wkts"
    FROM   "wicket_taken"   AS wt
    JOIN   "ball_by_ball"   AS bb  ON wt."match_id" = bb."match_id"
                                   AND wt."over_id"  = bb."over_id"
                                   AND wt."ball_id"  = bb."ball_id"
    JOIN   "match"          AS m   ON m."match_id"  = wt."match_id"
    WHERE  wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m."season_id", bb."bowler"
),

/* -----------------------------------------------------------
4) Keep TOP-3 bowlers (tie-breaker: smaller player_id)
----------------------------------------------------------- */
top_bowlers AS (
    SELECT *
    FROM (
        SELECT
            bt."season_id",
            bt."player_id"               AS "bowler_id",
            bt."total_wkts",
            ROW_NUMBER() OVER (PARTITION BY bt."season_id"
                               ORDER BY bt."total_wkts" DESC, bt."player_id" ASC) AS pos
        FROM bowler_totals bt
    )
    WHERE pos <= 3
)

/* -----------------------------------------------------------
5) Combine batsmen & bowlers by season and position
----------------------------------------------------------- */
SELECT
    b."season_id",
    b."pos"              AS "position",
    b."batsman_id",
    b."total_runs",
    w."bowler_id",
    w."total_wkts"
FROM   top_batsmen b
JOIN   top_bowlers w
       ON  b."season_id" = w."season_id"
       AND b."pos"       = w."pos"
ORDER BY
    b."season_id",
    b."pos";