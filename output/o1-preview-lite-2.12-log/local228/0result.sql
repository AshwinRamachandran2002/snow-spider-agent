WITH BatsmanTotalRuns AS (
    SELECT 
        m.season_id, 
        bb.striker AS batsman_id, 
        SUM(bs.runs_scored) AS total_runs
    FROM 
        batsman_scored bs
    INNER JOIN 
        ball_by_ball bb
    ON 
        bs.match_id = bb.match_id AND 
        bs.over_id = bb.over_id AND 
        bs.ball_id = bb.ball_id AND 
        bs.innings_no = bb.innings_no
    INNER JOIN 
        match m
    ON 
        bs.match_id = m.match_id
    GROUP BY 
        m.season_id, 
        bb.striker
),
BowlersTotalWickets AS (
    SELECT
        m.season_id,
        bb.bowler AS bowler_id,
        COUNT(*) AS total_wickets
    FROM 
        wicket_taken wt
    INNER JOIN 
        ball_by_ball bb
    ON 
        wt.match_id = bb.match_id AND 
        wt.over_id = bb.over_id AND 
        wt.ball_id = bb.ball_id AND 
        wt.innings_no = bb.innings_no
    INNER JOIN 
        match m
    ON 
        wt.match_id = m.match_id
    WHERE
        wt.kind_out NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY
        m.season_id,
        bb.bowler
),
RankedBatsmen AS (
    SELECT
        b.season_id,
        b.batsman_id,
        b.total_runs,
        (SELECT COUNT(*) + 1 FROM BatsmanTotalRuns b2 
         WHERE b2.season_id = b.season_id AND 
               (b2.total_runs > b.total_runs OR
                (b2.total_runs = b.total_runs AND b2.batsman_id < b.batsman_id)
               )
        ) AS batsman_rank
    FROM
        BatsmanTotalRuns b
),
RankedBowlers AS (
    SELECT
        bo.season_id,
        bo.bowler_id,
        bo.total_wickets,
        (SELECT COUNT(*) + 1 FROM BowlersTotalWickets bo2 
         WHERE bo2.season_id = bo.season_id AND 
               (bo2.total_wickets > bo.total_wickets OR
                (bo2.total_wickets = bo.total_wickets AND bo2.bowler_id < bo.bowler_id)
               )
        ) AS bowler_rank
    FROM
        BowlersTotalWickets bo
),
Top3Batsmen AS (
    SELECT
        season_id,
        batsman_rank,
        batsman_id,
        total_runs
    FROM
        RankedBatsmen
    WHERE
        batsman_rank <= 3
),
Top3Bowlers AS (
    SELECT
        season_id,
        bowler_rank,
        bowler_id,
        total_wickets
    FROM
        RankedBowlers
    WHERE
        bowler_rank <= 3
),
Combined AS (
    SELECT
        tb.season_id,
        tb.batsman_rank,
        tb.batsman_id,
        tb.total_runs,
        bo.bowler_id,
        bo.total_wickets
    FROM
        Top3Batsmen tb
    JOIN
        Top3Bowlers bo
    ON
        tb.season_id = bo.season_id AND
        tb.batsman_rank = bo.bowler_rank
)
SELECT
    season_id,
    MAX(CASE WHEN batsman_rank = 1 THEN batsman_id END) AS Batsman1_ID,
    MAX(CASE WHEN batsman_rank = 1 THEN total_runs END) AS Batsman1_TotalRuns,
    MAX(CASE WHEN batsman_rank = 1 THEN bowler_id END) AS Bowler1_ID,
    MAX(CASE WHEN batsman_rank = 1 THEN total_wickets END) AS Bowler1_TotalWickets,
    MAX(CASE WHEN batsman_rank = 2 THEN batsman_id END) AS Batsman2_ID,
    MAX(CASE WHEN batsman_rank = 2 THEN total_runs END) AS Batsman2_TotalRuns,
    MAX(CASE WHEN batsman_rank = 2 THEN bowler_id END) AS Bowler2_ID,
    MAX(CASE WHEN batsman_rank = 2 THEN total_wickets END) AS Bowler2_TotalWickets,
    MAX(CASE WHEN batsman_rank = 3 THEN batsman_id END) AS Batsman3_ID,
    MAX(CASE WHEN batsman_rank = 3 THEN total_runs END) AS Batsman3_TotalRuns,
    MAX(CASE WHEN batsman_rank = 3 THEN bowler_id END) AS Bowler3_ID,
    MAX(CASE WHEN batsman_rank = 3 THEN total_wickets END) AS Bowler3_TotalWickets
FROM
    Combined
GROUP BY
    season_id
ORDER BY
    season_id;