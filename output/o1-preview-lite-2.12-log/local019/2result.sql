SELECT w1.name AS winner_name, w2.name AS loser_name
FROM Matches m
JOIN Wrestlers w1 ON m.winner_id = w1.id
JOIN Wrestlers w2 ON m.loser_id = w2.id
JOIN Belts b ON m.title_id = b.id
WHERE b.name LIKE '%NXT%'
  AND m.title_change = 0
  AND m.duration IS NOT NULL AND m.duration != ''
  AND m.duration LIKE '%:%' AND m.duration NOT LIKE '%:%:%'
ORDER BY (
  CAST(SUBSTR(m.duration, 1, INSTR(m.duration, ':') - 1) AS INTEGER) * 60 +
  CAST(SUBSTR(m.duration, INSTR(m.duration, ':') + 1) AS INTEGER)
) ASC
LIMIT 1;