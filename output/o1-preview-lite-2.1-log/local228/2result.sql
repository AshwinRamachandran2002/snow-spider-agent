WITH batsman_totals AS (
    SELECT 
        m.season_id, 
        bb.striker AS player_id, 
        SUM(bs.runs_scored) AS total_runs
    FROM batsman_scored bs
    JOIN ball_by_ball bb ON bs.match_id = bb.match_id
                         AND bs.over_id = bb.over_id
                         AND bs.ball_id = bb.ball_id
                         AND bs.innings_no = bb.innings_no
    JOIN "match" m ON bb.match_id = m.match_id
    GROUP BY m.season_id, bb.striker
),
batsman_rankings AS (
    SELECT
        season_id,
        player_id,
        total_runs,
        ROW_NUMBER() OVER (PARTITION BY season_id ORDER BY total_runs DESC, player_id) AS rank
    FROM batsman_totals
),
top_batsmen AS (
    SELECT season_id, player_id, rank
    FROM batsman_rankings
    WHERE rank <= 3
),
batsman_pivot AS (
    SELECT 
        season_id, 
        MAX(CASE WHEN rank=1 THEN p.player_name END) AS Batsman1,
        MAX(CASE WHEN rank=2 THEN p.player_name END) AS Batsman2,
        MAX(CASE WHEN rank=3 THEN p.player_name END) AS Batsman3
        FROM top_batsmen tb
    JOIN player p ON tb.player_id = p.player_id
    GROUP BY season_id
),
bowler_totals AS (
    SELECT 
        m.season_id, 
        bb.bowler AS player_id, 
        COUNT(*) AS total_wickets
    FROM wicket_taken wt
    JOIN ball_by_ball bb ON wt.match_id = bb.match_id
                          AND wt.over_id = bb.over_id
                          AND wt.ball_id = bb.ball_id
                          AND wt.innings_no = bb.innings_no
    JOIN "match" m ON bb.match_id = m.match_id
    WHERE wt.kind_out NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, bb.bowler
),
bowler_rankings AS (
    SELECT
        season_id,
        player_id,
        total_wickets,
        ROW_NUMBER() OVER (PARTITION BY season_id ORDER BY total_wickets DESC, player_id) AS rank
    FROM bowler_totals
),
top_bowlers AS (
    SELECT season_id, player_id, rank
    FROM bowler_rankings
    WHERE rank <=3
),
bowler_pivot AS (
    SELECT 
        season_id, 
        MAX(CASE WHEN rank=1 THEN p.player_name END) AS Bowler1,
        MAX(CASE WHEN rank=2 THEN p.player_name END) AS Bowler2,
        MAX(CASE WHEN rank=3 THEN p.player_name END) AS Bowler3
    FROM top_bowlers tb
    JOIN player p ON tb.player_id = p.player_id
    GROUP BY season_id
)
SELECT
    batsman_pivot.season_id AS Season,
    batsman_pivot.Batsman1,
    batsman_pivot.Batsman2,
    batsman_pivot.Batsman3,
    bowler_pivot.Bowler1,
    bowler_pivot.Bowler2,
    bowler_pivot.Bowler3
FROM batsman_pivot
JOIN bowler_pivot ON batsman_pivot.season_id = bowler_pivot.season_id
ORDER BY Season;