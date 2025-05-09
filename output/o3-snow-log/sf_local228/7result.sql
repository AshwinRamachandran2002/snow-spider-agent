WITH player_runs AS (   -- total runs by every batsman in a season
    SELECT
        m."season_id",
        bb."striker"                           AS "player_id",
        SUM(bs."runs_scored")                  AS "total_runs"
    FROM "IPL"."IPL"."BATSMAN_SCORED" bs
    JOIN "IPL"."IPL"."BALL_BY_BALL" bb
      ON bb."match_id"   = bs."match_id"
     AND bb."innings_no" = bs."innings_no"
     AND bb."over_id"    = bs."over_id"
     AND bb."ball_id"    = bs."ball_id"
    JOIN "IPL"."IPL"."MATCH" m
      ON m."match_id" = bs."match_id"
    GROUP BY m."season_id", bb."striker"
),
ranked_batsmen AS (     -- rank batsmen, breaking ties with smaller player_id
    SELECT
        pr.*,
        ROW_NUMBER() OVER (PARTITION BY pr."season_id"
                           ORDER BY pr."total_runs" DESC, pr."player_id" ASC) AS "bat_rank"
    FROM player_runs pr
),
top_batsmen AS (        -- keep top-3 per season
    SELECT *
    FROM ranked_batsmen
    WHERE "bat_rank" <= 3
),

player_wkts AS (        -- total wickets by every bowler in a season (exclude specific dismissal kinds)
    SELECT
        m."season_id",
        bb."bowler"                         AS "player_id",
        COUNT(*)                            AS "total_wkts"
    FROM "IPL"."IPL"."WICKET_TAKEN" wt
    JOIN "IPL"."IPL"."BALL_BY_BALL" bb
      ON bb."match_id"   = wt."match_id"
     AND bb."innings_no" = wt."innings_no"
     AND bb."over_id"    = wt."over_id"
     AND bb."ball_id"    = wt."ball_id"
    JOIN "IPL"."IPL"."MATCH" m
      ON m."match_id" = wt."match_id"
    WHERE wt."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m."season_id", bb."bowler"
),
ranked_bowlers AS (     -- rank bowlers, breaking ties with smaller player_id
    SELECT
        pw.*,
        ROW_NUMBER() OVER (PARTITION BY pw."season_id"
                           ORDER BY pw."total_wkts" DESC, pw."player_id" ASC) AS "bowl_rank"
    FROM player_wkts pw
),
top_bowlers AS (        -- keep top-3 per season
    SELECT *
    FROM ranked_bowlers
    WHERE "bowl_rank" <= 3
)

-- pair batsmen and bowlers by matching rank within each season
SELECT
    b."season_id",
    b."player_id"  AS "batsman_id",
    b."total_runs",
    w."player_id"  AS "bowler_id",
    w."total_wkts"
FROM top_batsmen b
JOIN top_bowlers w
  ON w."season_id" = b."season_id"
 AND w."bowl_rank" = b."bat_rank"
ORDER BY
    b."season_id" ASC,
    b."bat_rank"  ASC;