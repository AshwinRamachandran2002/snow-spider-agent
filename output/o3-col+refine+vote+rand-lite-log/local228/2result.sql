WITH
--------------------------------------------------
-- 1) Runs by every batsman in each season
--------------------------------------------------
season_runs AS (
    SELECT   m.season_id,
             bb.striker                     AS player_id,
             SUM(bs.runs_scored)            AS total_runs
    FROM     batsman_scored  AS bs
    JOIN     ball_by_ball    AS bb
         ON  bs.match_id = bb.match_id
        AND bs.over_id  = bb.over_id
        AND bs.ball_id  = bb.ball_id
    JOIN     match          AS m
         ON  m.match_id  = bs.match_id
    GROUP BY m.season_id, bb.striker
),
--------------------------------------------------
-- 2) Top-3 batsmen per season (tie-break by id)
--------------------------------------------------
top_batsmen AS (
    SELECT *
    FROM (
        SELECT  season_id,
                player_id,
                total_runs,
                ROW_NUMBER() OVER (PARTITION BY season_id
                                   ORDER BY total_runs DESC, player_id) AS pos
        FROM    season_runs
    )
    WHERE pos <= 3
),
--------------------------------------------------
-- 3) Wickets for every bowler in each season
--    (exclude run-out, hit-wicket, retired-hurt)
--------------------------------------------------
season_wkts AS (
    SELECT   m.season_id,
             b.bowler                       AS player_id,
             COUNT(*)                       AS total_wkts
    FROM     wicket_taken   AS w
    JOIN     ball_by_ball   AS b
         ON  w.match_id = b.match_id
        AND w.over_id  = b.over_id
        AND w.ball_id  = b.ball_id
    JOIN     match         AS m
         ON  m.match_id = w.match_id
    WHERE    w.kind_out NOT IN ('run out',
                                'hit wicket',
                                'retired hurt')
    GROUP BY m.season_id, b.bowler
),
--------------------------------------------------
-- 4) Top-3 bowlers per season (tie-break by id)
--------------------------------------------------
top_bowlers AS (
    SELECT *
    FROM (
        SELECT  season_id,
                player_id,
                total_wkts,
                ROW_NUMBER() OVER (PARTITION BY season_id
                                   ORDER BY total_wkts DESC, player_id) AS pos
        FROM    season_wkts
    )
    WHERE pos <= 3
)
--------------------------------------------------
-- 5) Combine batsmen & bowlers (1↔1, 2↔2, 3↔3)
--------------------------------------------------
SELECT   b.season_id,
         b.player_id            AS batsman_id,
         b.total_runs,
         pb.player_name         AS batsman_name,
         w.player_id            AS bowler_id,
         w.total_wkts,
         pw.player_name         AS bowler_name
FROM     top_batsmen AS b
JOIN     top_bowlers AS w
       ON b.season_id = w.season_id
      AND b.pos       = w.pos
JOIN     player AS pb
       ON pb.player_id = b.player_id
JOIN     player AS pw
       ON pw.player_id = w.player_id
ORDER BY b.season_id, b.pos;