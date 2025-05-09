WITH batsman_runs AS (
    SELECT
        m.season_id,
        b.striker AS player_id,
        SUM(s.runs_scored) AS total_runs
    FROM batsman_scored AS s
    JOIN ball_by_ball AS b
        ON s.match_id = b.match_id
       AND s.over_id = b.over_id
       AND s.ball_id = b.ball_id
       AND s.innings_no = b.innings_no
    JOIN match AS m ON s.match_id = m.match_id
    GROUP BY m.season_id, b.striker
),
batsman_ranks AS (
    SELECT
        season_id,
        player_id,
        total_runs,
        ROW_NUMBER() OVER (PARTITION BY season_id ORDER BY total_runs DESC, player_id ASC) AS rank
    FROM batsman_runs
),
bowler_wickets AS (
    SELECT
        m.season_id,
        b.bowler AS player_id,
        COUNT(*) AS total_wickets
    FROM wicket_taken AS w
    JOIN ball_by_ball AS b
        ON w.match_id = b.match_id
       AND w.over_id = b.over_id
       AND w.ball_id = b.ball_id
       AND w.innings_no = b.innings_no
    JOIN match AS m ON w.match_id = m.match_id
    WHERE w.kind_out NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, b.bowler
),
bowler_ranks AS (
    SELECT
        season_id,
        player_id,
        total_wickets,
        ROW_NUMBER() OVER (PARTITION BY season_id ORDER BY total_wickets DESC, player_id ASC) AS rank
    FROM bowler_wickets
),
top_batsmen AS (
    SELECT season_id, rank, player_id AS batsman_id, total_runs
    FROM batsman_ranks
    WHERE rank <= 3
),
top_bowlers AS (
    SELECT season_id, rank, player_id AS bowler_id, total_wickets
    FROM bowler_ranks
    WHERE rank <= 3
),
top_players AS (
    SELECT
        b.season_id,
        b.rank,
        b.batsman_id,
        b.total_runs,
        bw.bowler_id,
        bw.total_wickets
    FROM top_batsmen b
    JOIN top_bowlers bw ON b.season_id = bw.season_id AND b.rank = bw.rank
)
SELECT
    season_id AS Season_ID,
    MAX(CASE WHEN rank = 1 THEN batsman_id END) AS Batsman1_ID,
    MAX(CASE WHEN rank = 1 THEN total_runs END) AS Batsman1_TotalRuns,
    MAX(CASE WHEN rank = 1 THEN bowler_id END) AS Bowler1_ID,
    MAX(CASE WHEN rank = 1 THEN total_wickets END) AS Bowler1_TotalWickets,
    MAX(CASE WHEN rank = 2 THEN batsman_id END) AS Batsman2_ID,
    MAX(CASE WHEN rank = 2 THEN total_runs END) AS Batsman2_TotalRuns,
    MAX(CASE WHEN rank = 2 THEN bowler_id END) AS Bowler2_ID,
    MAX(CASE WHEN rank = 2 THEN total_wickets END) AS Bowler2_TotalWickets,
    MAX(CASE WHEN rank = 3 THEN batsman_id END) AS Batsman3_ID,
    MAX(CASE WHEN rank = 3 THEN total_runs END) AS Batsman3_TotalRuns,
    MAX(CASE WHEN rank = 3 THEN bowler_id END) AS Bowler3_ID,
    MAX(CASE WHEN rank = 3 THEN total_wickets END) AS Bowler3_TotalWickets
FROM top_players
GROUP BY season_id
ORDER BY season_id;