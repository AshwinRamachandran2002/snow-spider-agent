WITH career AS (
    SELECT 
        player_id,
        SUM(g)  AS total_g,
        SUM(r)  AS total_r,
        SUM(h)  AS total_h,
        SUM(hr) AS total_hr
    FROM batting
    GROUP BY player_id
),
max_vals AS (
    SELECT 
        MAX(total_g)  AS max_g,
        MAX(total_r)  AS max_r,
        MAX(total_h)  AS max_h,
        MAX(total_hr) AS max_hr
    FROM career
)
SELECT p.name_given          AS given_name,
       'Games Played'        AS statistic,
       CAST(c.total_g AS REAL)             AS max_value
FROM career  AS c
JOIN max_vals AS m ON c.total_g = m.max_g
JOIN player   AS p ON p.player_id = c.player_id

UNION ALL
SELECT p.name_given,
       'Runs',
       CAST(c.total_r AS REAL)
FROM career  AS c
JOIN max_vals AS m ON c.total_r = m.max_r
JOIN player   AS p ON p.player_id = c.player_id

UNION ALL
SELECT p.name_given,
       'Hits',
       CAST(c.total_h AS REAL)
FROM career  AS c
JOIN max_vals AS m ON c.total_h = m.max_h
JOIN player   AS p ON p.player_id = c.player_id

UNION ALL
SELECT p.name_given,
       'Home Runs',
       CAST(c.total_hr AS REAL)
FROM career  AS c
JOIN max_vals AS m ON c.total_hr = m.max_hr
JOIN player   AS p ON p.player_id = c.player_id;