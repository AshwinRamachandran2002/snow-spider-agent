WITH player_runs AS (
    /* runs scored by every batsman in every match together with the team he represented */
    SELECT
        bb.match_id,
        bb.striker                    AS player_id,
        SUM(bs.runs_scored)           AS runs_in_match,
        pm.team_id
    FROM batsman_scored  bs
    JOIN ball_by_ball    bb
         ON  bb.match_id   = bs.match_id
         AND bb.over_id    = bs.over_id
         AND bb.ball_id    = bs.ball_id
         AND bb.innings_no = bs.innings_no
    /* take unique (match,player,team) pairs so the join does not duplicate rows */
    JOIN (SELECT DISTINCT match_id, player_id, team_id
          FROM player_match) pm
         ON pm.match_id = bb.match_id
        AND pm.player_id = bb.striker
    GROUP BY bb.match_id, bb.striker, pm.team_id
),
losing_side AS (
    /* identify the team that lost every match which had a winner */
    SELECT
        m.match_id,
        CASE
            WHEN m.team_1 = m.match_winner THEN m.team_2
            WHEN m.team_2 = m.match_winner THEN m.team_1
        END AS losing_team_id
    FROM match m
    WHERE m.match_winner IS NOT NULL            -- ignore ties / no‑results
)
SELECT DISTINCT p.player_name
FROM   player_runs  pr
JOIN   losing_side  ls  ON ls.match_id      = pr.match_id
                       AND ls.losing_team_id = pr.team_id
JOIN   player       p   ON p.player_id      = pr.player_id
WHERE  pr.runs_in_match >= 100;