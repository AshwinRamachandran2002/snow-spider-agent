SELECT wr1.name AS wrestler_1,
       wr2.name AS wrestler_2
FROM   Matches   AS m
JOIN   Belts     AS b   ON b.id = m.title_id
JOIN   Wrestlers AS wr1 ON wr1.id = m.winner_id
JOIN   Wrestlers AS wr2 ON wr2.id = m.loser_id
WHERE  b.name LIKE '%NXT%'            -- only NXT‑branded titles
  AND  m.title_change = 0             -- exclude matches with a title change
  AND  m.duration LIKE '%:%'          -- ensure a recorded time
ORDER BY
  CASE                                -- convert duration to total seconds
      WHEN m.duration LIKE '%:%:%' THEN
           CAST(substr(m.duration,1,instr(m.duration,':')-1) AS INTEGER) * 3600 +
           CAST(substr(
                    m.duration,
                    instr(m.duration,':')+1,
                    instr(substr(m.duration,instr(m.duration,':')+1),':')-1
                ) AS INTEGER) * 60 +
           CAST(substr(m.duration,length(m.duration)-1,2) AS INTEGER)
      ELSE
           CAST(substr(m.duration,1,instr(m.duration,':')-1) AS INTEGER) * 60 +
           CAST(substr(m.duration,instr(m.duration,':')+1) AS INTEGER)
  END,
  m.id                                -- secondary sort to break ties
LIMIT 1;