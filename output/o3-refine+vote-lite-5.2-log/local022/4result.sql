WITH player_runs AS (
    SELECT
        bb.match_id,
        bb.striker AS player_id,
        SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball AS bb
    JOIN batsman_scored AS bs
      ON bb.match_id = bs.match_id
     AND bb.over_id  = bs.over_id
     AND bb.ball_id  = bs.ball_id
     AND bb.innings_no = bs.innings_no
    GROUP BY bb.match_id, bb.striker
),
centuries AS (                     -- players who scored at least 100 in a match
    SELECT match_id, player_id
    FROM player_runs
    WHERE total_runs >= 100
),
player_team AS (                   -- side each player represented in that match
    SELECT match_id, player_id, team_id
    FROM player_match
),
loss_centuries AS (                -- centuries made for the losing side
    SELECT c.player_id
    FROM centuries      AS c
    JOIN player_team    AS pt ON pt.match_id = c.match_id
                              AND pt.player_id = c.player_id
    JOIN "match"        AS m  ON m.match_id = c.match_id
    WHERE m.match_winner IS NOT NULL
      AND pt.team_id <> m.match_winner        -- player's team lost
)
SELECT DISTINCT p.player_name
FROM player AS p
JOIN loss_centuries AS lc ON lc.player_id = p.player_id;