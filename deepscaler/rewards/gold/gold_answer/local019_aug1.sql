-- Task: List up to 100 matches for NXT titles (excluding titles with 'title change'), showing the title name, match duration, and the names of the two wrestlers involved.
SELECT
    b.name AS title,
    m.duration AS match_duration,
    w1.name AS winner,
    w2.name AS loser
FROM 
    "Belts" b
INNER JOIN "Matches" m ON m.title_id = b.id
INNER JOIN "Wrestlers" w1 ON w1.id = m.winner_id
INNER JOIN "Wrestlers" w2 ON w2.id = m.loser_id
INNER JOIN "Cards" c ON c.id = m.card_id
INNER JOIN "Promotions" p ON p.id = c.promotion_id
WHERE
    p.name = 'NXT'
    AND m.duration <> ''
    AND b.name <> ''
    AND b.name NOT LIKE '%title change%'
LIMIT 100