SELECT
       w1.name AS wrestler_1 ,
       w2.name AS wrestler_2
FROM   Matches    AS m
JOIN   Belts      AS b  ON b.id = m.title_id
JOIN   Wrestlers  AS w1 ON w1.id = CAST(m.winner_id AS INTEGER)
JOIN   Wrestlers  AS w2 ON w2.id = CAST(m.loser_id  AS INTEGER)
WHERE  m.id = (
        SELECT m2.id
        FROM   Matches AS m2
        JOIN   Belts   AS b2 ON b2.id = m2.title_id
        WHERE  b2.name LIKE '%NXT%'        -- only NXT-related belts
          AND  m2.title_change = 0         -- exclude actual title changes
          AND  m2.duration LIKE '%:%'      -- keep rows with a recorded time
        ORDER BY
              (CAST(substr(m2.duration,1,instr(m2.duration,':')-1) AS INTEGER)*60 +
               CAST(substr(m2.duration,instr(m2.duration,':')+1)   AS INTEGER))
        ASC                                 -- shortest duration first
        LIMIT 1
);