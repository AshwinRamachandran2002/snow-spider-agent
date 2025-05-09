WITH nxt_belts AS (
    SELECT id
    FROM Belts
    WHERE name LIKE '%NXT%'
),
nxt_matches AS (
    SELECT m.*,
           (CAST(substr(m.duration, 1, instr(m.duration, ':') - 1) AS INTEGER) * 60 +
            CAST(substr(m.duration, instr(m.duration, ':') + 1) AS INTEGER)) AS seconds
    FROM Matches AS m
    WHERE m.title_id IN (SELECT id FROM nxt_belts)
      AND m.title_change = 0
      AND m.duration LIKE '%:%'
),
shortest_match AS (
    SELECT id
    FROM nxt_matches
    ORDER BY seconds
    LIMIT 1
)
SELECT w1.name AS winner_name,
       w2.name AS loser_name
FROM Matches AS m
JOIN Wrestlers AS w1 ON w1.id = m.winner_id
JOIN Wrestlers AS w2 ON w2.id = m.loser_id
WHERE m.id = (SELECT id FROM shortest_match);