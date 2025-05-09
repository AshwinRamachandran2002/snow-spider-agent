SELECT DISTINCT
       p.player_name
FROM   (
           /* 1. 100+ individual scores in a match */
           SELECT bb.match_id,
                  bb.striker AS player_id,
                  SUM(bs.runs_scored) AS total_runs
           FROM   ball_by_ball  AS bb
           JOIN   batsman_scored AS bs
                  ON  bb.match_id   = bs.match_id
                  AND bb.over_id    = bs.over_id
                  AND bb.ball_id    = bs.ball_id
                  AND bb.innings_no = bs.innings_no
           GROUP  BY bb.match_id,
                     bb.striker
           HAVING SUM(bs.runs_scored) >= 100
       ) AS r
       /* 2. Identify the team that the scorer represented in that match */
JOIN   player_match AS pm
       ON  r.match_id  = pm.match_id
       AND r.player_id = pm.player_id
/* 3. Match details to get the winning side */
JOIN   "match" AS m
       ON  r.match_id = m.match_id
/* 4. Player information */
JOIN   player AS p
       ON  r.player_id = p.player_id
/* 5. Filter so that the player's team is NOT the winner */
WHERE  pm.team_id <> m.match_winner
       AND m.match_winner IS NOT NULL;