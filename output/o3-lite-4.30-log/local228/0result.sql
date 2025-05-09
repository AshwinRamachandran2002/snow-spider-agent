WITH bats AS (
    /* total runs for every batsman in every season */
    SELECT
        m."season_id",
        bb."striker"                      AS batsman_id,
        SUM(bs."runs_scored")             AS total_runs
    FROM "batsman_scored" AS bs
    JOIN "ball_by_ball"  AS bb
      ON bs."match_id"   = bb."match_id"
     AND bs."over_id"    = bb."over_id"
     AND bs."ball_id"    = bb."ball_id"
     AND bs."innings_no" = bb."innings_no"
    JOIN "match"         AS m
      ON m."match_id"    = bs."match_id"
    GROUP BY m."season_id", bb."striker"
),
bats_ranked AS (
    SELECT
        season_id,
        batsman_id,
        total_runs,
        ROW_NUMBER() OVER (
            PARTITION BY season_id
            ORDER BY total_runs DESC, batsman_id ASC
        ) AS rn
    FROM bats
),
bats_top AS (
    SELECT * FROM bats_ranked WHERE rn <= 3
),
wkts AS (
    /* total qualified wickets for every bowler in every season */
    SELECT
        m."season_id",
        bb."bowler"                       AS bowler_id,
        COUNT(*)                          AS total_wkts
    FROM "wicket_taken" AS w
    JOIN "ball_by_ball" AS bb
      ON w."match_id"   = bb."match_id"
     AND w."over_id"    = bb."over_id"
     AND w."ball_id"    = bb."ball_id"
     AND w."innings_no" = bb."innings_no"
    JOIN "match"        AS m
      ON m."match_id"   = w."match_id"
    WHERE w."kind_out" NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m."season_id", bb."bowler"
),
wkts_ranked AS (
    SELECT
        season_id,
        bowler_id,
        total_wkts,
        ROW_NUMBER() OVER (
            PARTITION BY season_id
            ORDER BY total_wkts DESC, bowler_id ASC
        ) AS rn
    FROM wkts
),
wkts_top AS (
    SELECT * FROM wkts_ranked WHERE rn <= 3
),
joined AS (
    /* align batsman‑rank N with bowler‑rank N for every season */
    SELECT
        b.season_id,
        b.rn,
        b.batsman_id,
        b.total_runs,
        w.bowler_id,
        w.total_wkts
    FROM bats_top AS b
    JOIN wkts_top AS w
      ON b.season_id = w.season_id
     AND b.rn        = w.rn
)
SELECT
    season_id,
    MAX(CASE WHEN rn = 1 THEN batsman_id END)  AS batsman1_id,
    MAX(CASE WHEN rn = 1 THEN total_runs END)  AS batsman1_total_runs,
    MAX(CASE WHEN rn = 1 THEN bowler_id  END)  AS bowler1_id,
    MAX(CASE WHEN rn = 1 THEN total_wkts END)  AS bowler1_total_wickets,
    MAX(CASE WHEN rn = 2 THEN batsman_id END)  AS batsman2_id,
    MAX(CASE WHEN rn = 2 THEN total_runs END)  AS batsman2_total_runs,
    MAX(CASE WHEN rn = 2 THEN bowler_id  END)  AS bowler2_id,
    MAX(CASE WHEN rn = 2 THEN total_wkts END)  AS bowler2_total_wickets,
    MAX(CASE WHEN rn = 3 THEN batsman_id END)  AS batsman3_id,
    MAX(CASE WHEN rn = 3 THEN total_runs END)  AS batsman3_total_runs,
    MAX(CASE WHEN rn = 3 THEN bowler_id  END)  AS bowler3_id,
    MAX(CASE WHEN rn = 3 THEN total_wkts END)  AS bowler3_total_wickets
FROM joined
GROUP BY season_id
ORDER BY season_id;