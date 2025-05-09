SELECT w1.name AS wrestler_1,
       w2.name AS wrestler_2
FROM Matches AS m
JOIN Wrestlers AS w1 ON w1.id = CAST(m.winner_id AS INTEGER)
JOIN Wrestlers AS w2 ON w2.id = CAST(m.loser_id  AS INTEGER)
WHERE m.title_id IN (SELECT id FROM Belts WHERE name LIKE '%NXT%')
  AND m.title_change = 0
  AND m.duration GLOB '[0-9][0-9]:[0-9][0-9]'
ORDER BY (CAST(substr(m.duration,1,2) AS INTEGER) * 60 
          + CAST(substr(m.duration,4,2) AS INTEGER))
LIMIT 1;