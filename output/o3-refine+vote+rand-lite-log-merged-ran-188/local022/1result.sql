WITH player_runs AS (
    /* runs scored by every batsman in every match */
    SELECT 
        bb.match_id,
        bb.striker            AS player_id,
        SUM(bs.runs_scored)   AS total_runs
    FROM batsman_scored  bs
    JOIN ball_by_ball    bb
      ON  bb.match_id   = bs.match_id
      AND bb.over_id    = bs.over_id
      AND bb.ball_id    = bs.ball_id
      AND bb.innings_no = bs.innings_no
    GROUP BY bb.match_id, bb.striker
),
player_team AS (
    /* team for which each player appeared in a match */
    SELECT 
        match_id,
        player_id,
        team_id
    FROM player_match
),
lost_centuries AS (
    /* players who hit 100+ but their team did not win */
    SELECT DISTINCT
        pr.player_id
    FROM player_runs  pr
    JOIN player_team  pt ON pr.match_id = pt.match_id
                        AND pr.player_id = pt.player_id
    JOIN "match"     m  ON pr.match_id = m.match_id
    WHERE pr.total_runs >= 100              -- century or more
      AND m.match_winner IS NOT NULL        -- match had a winner
      AND pt.team_id <> m.match_winner      -- player’s team lost
)
SELECT DISTINCT p.player_name
FROM lost_centuries lc
JOIN player p ON p.player_id = lc.player_id;