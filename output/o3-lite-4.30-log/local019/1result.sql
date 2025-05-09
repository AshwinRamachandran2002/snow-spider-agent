SELECT w1.name AS wrestler_1,
       w2.name AS wrestler_2
FROM Matches   AS m
JOIN Belts     AS b  ON b.id = m.title_id
JOIN Wrestlers AS w1 ON w1.id = m.winner_id
JOIN Wrestlers AS w2 ON w2.id = m.loser_id
WHERE b.name LIKE '%NXT%'
  AND m.duration <> ''
  AND m.title_change = 0
ORDER BY LENGTH(m.duration), m.duration
LIMIT 1;