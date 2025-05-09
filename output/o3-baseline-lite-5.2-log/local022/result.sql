WITH player_runs AS (
    SELECT
        bb.match_id,
        bb.team_batting           AS team_id,
        bb.striker                AS player_id,
        SUM(bs.runs_scored)       AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball  AS bb
          ON bb.match_id   = bs.match_id
         AND bb.over_id    = bs.over_id
         AND bb.ball_id    = bs.ball_id
         AND bb.innings_no = bs.innings_no
    GROUP BY bb.match_id, bb.team_batting, bb.striker
),
centuries AS (
    SELECT *
    FROM player_runs
    WHERE total_runs >= 100
),
centuries_for_losing_team AS (
    SELECT c.*
    FROM centuries AS c
    JOIN match  AS m
      ON m.match_id = c.match_id
    WHERE m.match_winner IS NOT NULL      -- ensure a result
      AND c.team_id <> m.match_winner     -- player’s team lost
)
SELECT DISTINCT p.player_name
FROM centuries_for_losing_team AS l
JOIN player AS p
  ON p.player_id = l.player_id
ORDER BY p.player_name;