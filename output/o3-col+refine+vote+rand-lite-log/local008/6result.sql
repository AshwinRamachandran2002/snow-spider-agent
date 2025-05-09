WITH
  g_max AS (SELECT MAX(g)  AS val FROM batting  WHERE g  IS NOT NULL),
  r_max AS (SELECT MAX(r)  AS val FROM batting  WHERE r  IS NOT NULL),
  h_max AS (SELECT MAX(h)  AS val FROM batting  WHERE h  IS NOT NULL),
  hr_max AS (SELECT MAX(hr) AS val FROM batting  WHERE hr IS NOT NULL)

SELECT 'Games Played' AS metric, p.name_given AS player, b.g  AS value
FROM batting  b
JOIN player   p ON p.player_id = b.player_id
JOIN g_max    m ON b.g  = m.val

UNION ALL
SELECT 'Runs'        , p.name_given          , b.r          AS value
FROM batting  b
JOIN player   p ON p.player_id = b.player_id
JOIN r_max    m ON b.r  = m.val

UNION ALL
SELECT 'Hits'        , p.name_given          , b.h          AS value
FROM batting  b
JOIN player   p ON p.player_id = b.player_id
JOIN h_max    m ON b.h = m.val

UNION ALL
SELECT 'Home Runs'   , p.name_given          , b.hr         AS value
FROM batting  b
JOIN player   p ON p.player_id = b.player_id
JOIN hr_max   m ON b.hr = m.val;