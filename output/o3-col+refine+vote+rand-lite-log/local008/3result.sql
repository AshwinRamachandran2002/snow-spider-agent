WITH max_values AS (
    SELECT
        (SELECT MAX(g)  FROM batting) AS max_g,
        (SELECT MAX(r)  FROM batting) AS max_r,
        (SELECT MAX(h)  FROM batting) AS max_h,
        (SELECT MAX(hr) FROM batting) AS max_hr
)
SELECT 'Games Played' AS record_type,
       p.name_given,
       b.g AS record_value
FROM batting b
JOIN player  p USING (player_id)
JOIN max_values mv
WHERE b.g = mv.max_g

UNION ALL
SELECT 'Runs',
       p.name_given,
       b.r
FROM batting b
JOIN player p USING (player_id)
JOIN max_values mv
WHERE b.r = mv.max_r

UNION ALL
SELECT 'Hits',
       p.name_given,
       b.h
FROM batting b
JOIN player p USING (player_id)
JOIN max_values mv
WHERE b.h = mv.max_h

UNION ALL
SELECT 'Home Runs',
       p.name_given,
       b.hr
FROM batting b
JOIN player p USING (player_id)
JOIN max_values mv
WHERE b.hr = mv.max_hr;