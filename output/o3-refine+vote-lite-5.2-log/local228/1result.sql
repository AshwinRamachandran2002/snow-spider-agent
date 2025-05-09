WITH
-- total runs scored by every batsman in each season
batsman_runs AS (
    SELECT
        m.season_id,
        bb.striker         AS player_id,
        SUM(bs.runs_scored) AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS bb
      ON bb.match_id  = bs.match_id
     AND bb.over_id   = bs.over_id
     AND bb.ball_id   = bs.ball_id
     AND bb.innings_no = bs.innings_no
    JOIN "match"  AS m
      ON m.match_id = bs.match_id
    GROUP BY m.season_id, bb.striker
),
-- keep only the best three batsmen of every season
batsman_top AS (
    SELECT
        season_id,
        player_id,
        total_runs,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_runs DESC, player_id ASC) AS pos
    FROM batsman_runs
),
batsman3 AS (
    SELECT * FROM batsman_top WHERE pos <= 3
),

-- total wickets taken by every bowler in each season
bowler_wkts AS (
    SELECT
        m.season_id,
        bb.bowler       AS player_id,
        COUNT(*)        AS total_wkts
    FROM wicket_taken AS wt
    JOIN ball_by_ball AS bb
      ON bb.match_id  = wt.match_id
     AND bb.over_id   = wt.over_id
     AND bb.ball_id   = wt.ball_id
     AND bb.innings_no = wt.innings_no
    JOIN "match" AS m
      ON m.match_id = wt.match_id
    WHERE wt.kind_out NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, bb.bowler
),
-- keep only the best three bowlers of every season
bowler_top AS (
    SELECT
        season_id,
        player_id,
        total_wkts,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_wkts DESC, player_id ASC) AS pos
    FROM bowler_wkts
),
bowler3 AS (
    SELECT * FROM bowler_top WHERE pos <= 3
),

-- pivot the three batsmen and bowlers into one row per season
combined AS (
    SELECT
        s.season_id,

        MAX(CASE WHEN b.pos = 1 THEN b.player_id  END) AS batsman1_id,
        MAX(CASE WHEN b.pos = 1 THEN b.total_runs END) AS batsman1_runs,
        MAX(CASE WHEN w.pos = 1 THEN w.player_id  END) AS bowler1_id,
        MAX(CASE WHEN w.pos = 1 THEN w.total_wkts END) AS bowler1_wkts,

        MAX(CASE WHEN b.pos = 2 THEN b.player_id  END) AS batsman2_id,
        MAX(CASE WHEN b.pos = 2 THEN b.total_runs END) AS batsman2_runs,
        MAX(CASE WHEN w.pos = 2 THEN w.player_id  END) AS bowler2_id,
        MAX(CASE WHEN w.pos = 2 THEN w.total_wkts END) AS bowler2_wkts,

        MAX(CASE WHEN b.pos = 3 THEN b.player_id  END) AS batsman3_id,
        MAX(CASE WHEN b.pos = 3 THEN b.total_runs END) AS batsman3_runs,
        MAX(CASE WHEN w.pos = 3 THEN w.player_id  END) AS bowler3_id,
        MAX(CASE WHEN w.pos = 3 THEN w.total_wkts END) AS bowler3_wkts

    FROM (SELECT DISTINCT season_id FROM "match") AS s
    LEFT JOIN batsman3 AS b ON b.season_id = s.season_id
    LEFT JOIN bowler3  AS w ON w.season_id = s.season_id
    GROUP BY s.season_id
)

SELECT *
FROM combined
ORDER BY season_id;