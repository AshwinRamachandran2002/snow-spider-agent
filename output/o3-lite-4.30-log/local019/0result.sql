SELECT
  w1.name AS wrestler_1,
  w2.name AS wrestler_2
FROM Matches AS m
JOIN Belts     AS b  ON b.id = m.title_id
JOIN Wrestlers AS w1 ON w1.id = CAST(m.winner_id AS INTEGER)
JOIN Wrestlers AS w2 ON w2.id = CAST(m.loser_id  AS INTEGER)
WHERE b.name LIKE '%NXT%'
  AND m.title_change = 0
  AND m.duration <> ''
ORDER BY (CAST(substr(m.duration, 1, instr(m.duration, ':') - 1) AS INTEGER) * 60 +
          CAST(substr(m.duration, instr(m.duration, ':') + 1)        AS INTEGER)) ASC,
         m.id ASC
LIMIT 1;