SELECT DISTINCT
       w1.name AS wrestler_1,
       w2.name AS wrestler_2
FROM Matches   AS m
JOIN Belts     AS b  ON b.id = m.title_id
JOIN Wrestlers AS w1 ON w1.id = CAST(m.winner_id AS INTEGER)
JOIN Wrestlers AS w2 ON w2.id = CAST(m.loser_id  AS INTEGER)
WHERE b.name LIKE '%NXT%'                -- only NXT-related titles
  AND m.duration LIKE '%:%'              -- keep matches with a mm:ss duration
  AND m.title_change = 0                 -- exclude title-change bouts
  AND (CAST(SUBSTR(m.duration,1,INSTR(m.duration,':')-1) AS INTEGER) * 60 +
       CAST(SUBSTR(m.duration,INSTR(m.duration,':')+1)  AS INTEGER)
      ) = (
        -- shortest duration (in seconds) for non-changing NXT title matches
        SELECT MIN(CAST(SUBSTR(duration,1,INSTR(duration,':')-1) AS INTEGER) * 60 +
                   CAST(SUBSTR(duration,INSTR(duration,':')+1)  AS INTEGER))
        FROM Matches
        WHERE title_id IN (SELECT id FROM Belts WHERE name LIKE '%NXT%')
          AND duration LIKE '%:%'
          AND title_change = 0
      );