WITH nxt_matches AS (
    SELECT  m.*,
            CAST(substr(m.duration,1,instr(m.duration,':')-1) AS INT)*60 +
            CAST(substr(m.duration,instr(m.duration,':')+1) AS INT) AS seconds
    FROM    Matches AS m
    JOIN    Belts   AS b ON b.id = m.title_id
    WHERE   b.name LIKE '%NXT%'          -- any NXT-branded championship
      AND   m.title_change = 0           -- no title change
      AND   TRIM(IFNULL(m.duration,'')) <> ''   -- duration present
),
shortest AS (
    SELECT *
    FROM   nxt_matches
    WHERE  seconds = (SELECT MIN(seconds) FROM nxt_matches)
)
SELECT DISTINCT
       w1.name AS wrestler_1,
       w2.name AS wrestler_2
FROM   shortest AS s
JOIN   Wrestlers AS w1 ON w1.id = CAST(s.winner_id AS INT)
JOIN   Wrestlers AS w2 ON w2.id = CAST(s.loser_id  AS INT);