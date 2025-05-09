WITH
-- aggregate & rank batsmen
bats AS (
    SELECT
        m."season_id",
        bb."striker"                  AS "batsman_id",
        SUM(bs."runs_scored")         AS "total_runs",
        ROW_NUMBER() OVER (
            PARTITION BY m."season_id"
            ORDER BY SUM(bs."runs_scored") DESC,
                     bb."striker"
        )                             AS rn
    FROM "match"            AS m
    JOIN "ball_by_ball"     AS bb ON m."match_id" = bb."match_id"
    JOIN "batsman_scored"   AS bs USING ("match_id","over_id","ball_id","innings_no")
    GROUP BY m."season_id", bb."striker"
),
top_bats AS (
    SELECT
        b."season_id",
        b.rn,
        p."player_name"               AS "batsman_name",
        b."batsman_id",
        b."total_runs"
    FROM bats AS b
    JOIN "player"  AS p ON p."player_id" = b."batsman_id"
    WHERE b.rn <= 3
),

-- aggregate & rank bowlers
wkts AS (
    SELECT
        m."season_id",
        bb."bowler"                   AS "bowler_id",
        COUNT(*)                      AS "total_wkts",
        ROW_NUMBER() OVER (
            PARTITION BY m."season_id"
            ORDER BY COUNT(*) DESC,
                     bb."bowler"
        )                             AS rn
    FROM "wicket_taken"   AS wt
    JOIN "ball_by_ball"   AS bb
         ON  wt."match_id"   = bb."match_id"
         AND wt."over_id"    = bb."over_id"
         AND wt."ball_id"    = bb."ball_id"
         AND wt."innings_no" = bb."innings_no"
    JOIN "match"          AS m  ON m."match_id" = wt."match_id"
    WHERE wt."kind_out" NOT IN ('run out','hit wicket','retired hurt')
    GROUP BY m."season_id", bb."bowler"
),
top_bowl AS (
    SELECT
        w."season_id",
        w.rn,
        p."player_name"               AS "bowler_name",
        w."bowler_id",
        w."total_wkts"
    FROM wkts AS w
    JOIN "player"  AS p ON p."player_id" = w."bowler_id"
    WHERE w.rn <= 3
)

-- combine corresponding ranks
SELECT
    tb."season_id",
    tb."batsman_id",
    tb."batsman_name",
    tb."total_runs",
    tw."bowler_id",
    tw."bowler_name",
    tw."total_wkts"
FROM top_bats AS tb
JOIN top_bowl AS tw
  ON  tb."season_id" = tw."season_id"
  AND tb.rn          = tw.rn
ORDER BY tb."season_id", tb.rn;