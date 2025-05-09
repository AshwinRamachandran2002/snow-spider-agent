SELECT 
    w1.name AS winner_name,
    w2.name AS loser_name
FROM Matches AS m
JOIN Belts      AS b  ON b.id = m.title_id
JOIN Wrestlers  AS w1 ON w1.id = m.winner_id
JOIN Wrestlers  AS w2 ON w2.id = m.loser_id
WHERE b.name LIKE '%NXT%'          -- only NXT title matches
  AND m.title_change = 0           -- exclude matches with a title change
  AND m.duration <> ''             -- only matches with a recorded duration
ORDER BY
      (CAST(substr(m.duration,1,instr(m.duration,':')-1) AS INTEGER)*60 +   -- minutes → seconds
       CAST(substr(m.duration,instr(m.duration,':')+1)   AS INTEGER))       -- seconds
LIMIT 1;