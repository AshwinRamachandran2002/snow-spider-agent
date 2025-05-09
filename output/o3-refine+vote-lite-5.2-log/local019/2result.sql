WITH nxt_matches AS (
    SELECT
        m.id,
        m.winner_id,
        m.loser_id,
        -- convert duration to total seconds
        CASE
            -- format MM:SS
            WHEN (LENGTH(m.duration) - LENGTH(REPLACE(m.duration, ':', ''))) = 1 THEN
                CAST(SUBSTR(m.duration, 1, INSTR(m.duration, ':') - 1) AS INTEGER) * 60 +
                CAST(SUBSTR(m.duration, INSTR(m.duration, ':') + 1) AS INTEGER)
            -- format HH:MM:SS
            WHEN (LENGTH(m.duration) - LENGTH(REPLACE(m.duration, ':', ''))) = 2 THEN
                CAST(SUBSTR(m.duration, 1, INSTR(m.duration, ':') - 1) AS INTEGER) * 3600 +
                CAST(SUBSTR(m.duration, INSTR(m.duration, ':') + 1, 2) AS INTEGER) * 60 +
                CAST(SUBSTR(m.duration, LENGTH(m.duration) - 1, 2) AS INTEGER)
        END AS total_seconds
    FROM Matches m
    JOIN Belts  b ON b.id = m.title_id
    WHERE b.name LIKE '%NXT%'        -- only NXT titles
      AND m.title_change = 0         -- exclude title changes
      AND m.duration <> ''           -- ensure duration exists
)
SELECT
    w1.name AS winner_name,
    w2.name AS loser_name
FROM nxt_matches nm
JOIN Wrestlers w1 ON w1.id = CAST(nm.winner_id AS INTEGER)
JOIN Wrestlers w2 ON w2.id = CAST(nm.loser_id AS INTEGER)
WHERE nm.total_seconds = (
    SELECT MIN(total_seconds) FROM nxt_matches
)
LIMIT 1;