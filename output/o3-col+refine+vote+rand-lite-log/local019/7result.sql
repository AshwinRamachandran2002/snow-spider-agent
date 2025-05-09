SELECT
    w_win.name  AS winner_name,
    w_los.name  AS loser_name
FROM Matches  AS m
JOIN Belts     AS b   ON b.id = m.title_id
JOIN Wrestlers AS w_win ON w_win.id = m.winner_id
JOIN Wrestlers AS w_los ON w_los.id = m.loser_id
WHERE b.name LIKE '%NXT%'          -- only NXT–related championships
  AND m.title_change = 0           -- exclude matches where the title changed hands
  AND m.duration <> ''             -- keep matches that have a recorded duration
  AND m.duration = (               -- match(es) with the overall shortest duration
        SELECT MIN(duration)
        FROM Matches
        WHERE title_change = 0
          AND duration <> ''
          AND title_id IN (SELECT id FROM Belts WHERE name LIKE '%NXT%')
      );