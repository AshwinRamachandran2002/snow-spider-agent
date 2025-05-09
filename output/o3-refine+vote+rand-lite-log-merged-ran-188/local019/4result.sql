SELECT 
    w1.name AS winner_name,
    w2.name AS loser_name
FROM Matches AS m
JOIN Belts     AS b  ON b.id = m.title_id
JOIN Wrestlers AS w1 ON w1.id = CAST(m.winner_id AS INTEGER)
JOIN Wrestlers AS w2 ON w2.id = CAST(m.loser_id  AS INTEGER)
WHERE b.name LIKE '%NXT%'               -- keep only NXT titles
  AND m.title_change = 0                -- exclude title‑change matches
  AND m.duration <> ''                  -- keep matches with a recorded time
  AND m.duration IS NOT NULL
ORDER BY
    (CAST(substr(m.duration, 1, instr(m.duration, ':')-1) AS INTEGER) * 60 +
     CAST(substr(m.duration, instr(m.duration, ':')+1)   AS INTEGER))  -- total seconds
ASC
LIMIT 1;