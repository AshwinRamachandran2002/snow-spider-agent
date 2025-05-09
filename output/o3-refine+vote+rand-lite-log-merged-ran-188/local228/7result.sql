WITH runs_per_player AS (
    SELECT 
        m.season_id,
        bb.striker                AS player_id,
        SUM(bs.runs_scored)       AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS bb
         ON bs.match_id   = bb.match_id
        AND bs.over_id    = bb.over_id
        AND bs.ball_id    = bb.ball_id
        AND bs.innings_no = bb.innings_no
    JOIN match AS m
         ON bs.match_id = m.match_id
    GROUP BY m.season_id, bb.striker
),
top_batsmen AS (
    SELECT
        season_id,
        player_id     AS batsman_id,
        total_runs,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_runs DESC, player_id ASC) AS pos
    FROM runs_per_player
),
wickets_per_bowler AS (
    SELECT
        m.season_id,
        bb.bowler           AS player_id,
        COUNT(*)            AS total_wkts
    FROM wicket_taken AS w
    JOIN ball_by_ball AS bb
         ON w.match_id   = bb.match_id
        AND w.over_id    = bb.over_id
        AND w.ball_id    = bb.ball_id
        AND w.innings_no = bb.innings_no
    JOIN match AS m
         ON w.match_id = m.match_id
    WHERE w.kind_out NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, bb.bowler
),
top_bowlers AS (
    SELECT
        season_id,
        player_id   AS bowler_id,
        total_wkts,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_wkts DESC, player_id ASC) AS pos
    FROM wickets_per_bowler
)
SELECT
    b.season_id                    AS season_id,
    b.pos                          AS position,
    b.batsman_id                   AS batsman_player_id,
    b.total_runs                   AS batsman_total_runs,
    w.bowler_id                    AS bowler_player_id,
    w.total_wkts                   AS bowler_total_wickets
FROM (SELECT * FROM top_batsmen WHERE pos <= 3) AS b
JOIN (SELECT * FROM top_bowlers WHERE pos <= 3) AS w
     ON b.season_id = w.season_id
    AND b.pos       = w.pos
ORDER BY b.season_id, b.pos;