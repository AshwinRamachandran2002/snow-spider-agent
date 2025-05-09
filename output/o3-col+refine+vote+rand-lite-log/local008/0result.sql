WITH nb AS (          -- cast blank text values to integers (becomes 0) so MAX works numerically
    SELECT
        player_id,
        CAST(g  AS INTEGER)  AS g,
        CAST(r  AS INTEGER)  AS r,
        CAST(h  AS INTEGER)  AS h,
        CAST(hr AS INTEGER)  AS hr
    FROM batting
),
mx AS (                -- store the four leaderboard highs
    SELECT
        MAX(g)  AS max_g,
        MAX(r)  AS max_r,
        MAX(h)  AS max_h,
        MAX(hr) AS max_hr
    FROM nb
)
SELECT 'Games Played' AS category,
       nb.player_id,
       p.name_first,
       p.name_last,
       nb.g            AS value
FROM nb
JOIN player p ON p.player_id = nb.player_id
JOIN mx       ON nb.g  = mx.max_g

UNION ALL
SELECT 'Runs',
       nb.player_id,
       p.name_first,
       p.name_last,
       nb.r
FROM nb
JOIN player p ON p.player_id = nb.player_id
JOIN mx       ON nb.r = mx.max_r

UNION ALL
SELECT 'Hits',
       nb.player_id,
       p.name_first,
       p.name_last,
       nb.h
FROM nb
JOIN player p ON p.player_id = nb.player_id
JOIN mx       ON nb.h = mx.max_h

UNION ALL
SELECT 'Home Runs',
       nb.player_id,
       p.name_first,
       p.name_last,
       nb.hr
FROM nb
JOIN player p ON p.player_id = nb.player_id
JOIN mx       ON nb.hr = mx.max_hr;