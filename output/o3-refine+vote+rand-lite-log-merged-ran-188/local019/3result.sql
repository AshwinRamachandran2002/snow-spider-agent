SELECT
    w1.name AS wrestler1,
    w2.name AS wrestler2
FROM
    Matches  m
    JOIN Belts      b  ON b.id = m.title_id
    JOIN Wrestlers  w1 ON w1.id = CAST(m.winner_id AS INTEGER)
    JOIN Wrestlers  w2 ON w2.id = CAST(m.loser_id  AS INTEGER)
WHERE
    b.name LIKE '%NXT%'          -- only NXT titles
    AND m.title_change = 0       -- exclude title changes
    AND m.duration IS NOT NULL
    AND m.duration <> ''         -- keep only matches with a duration
ORDER BY
    /* convert duration (mm:ss or hh:mm:ss) into total seconds */
    CASE
        WHEN (length(m.duration) - length(REPLACE(m.duration, ':', ''))) = 2
        THEN  /* format hh:mm:ss */
             (CAST(substr(m.duration, 1, instr(m.duration, ':') - 1) AS INTEGER) * 3600) +
             (CAST(substr(
                     m.duration,
                     instr(m.duration, ':') + 1,
                     instr(substr(m.duration, instr(m.duration, ':') + 1), ':') - 1
                 ) AS INTEGER) * 60) +
             CAST(substr(m.duration, length(m.duration) - 1, 2) AS INTEGER)
        ELSE  /* assume format mm:ss */
             (CAST(substr(m.duration, 1, instr(m.duration, ':') - 1) AS INTEGER) * 60) +
             CAST(substr(m.duration, instr(m.duration, ':') + 1) AS INTEGER)
    END
LIMIT 1;