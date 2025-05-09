WITH totals AS (
    SELECT
        player_id,
        SUM(COALESCE(g,0))  AS g_total,
        SUM(COALESCE(r,0))  AS r_total,
        SUM(COALESCE(h,0))  AS h_total,
        SUM(COALESCE(hr,0)) AS hr_total
    FROM batting
    GROUP BY player_id
),
max_vals AS (
    SELECT
        MAX(g_total)  AS max_g,
        MAX(r_total)  AS max_r,
        MAX(h_total)  AS max_h,
        MAX(hr_total) AS max_hr
    FROM totals
)
SELECT 'Games Played' AS category,
       p.name_given    AS player_given_name,
       t.g_total       AS value
FROM totals t
JOIN max_vals m              ON t.g_total = m.max_g
JOIN player    p             ON p.player_id = t.player_id

UNION ALL
SELECT 'Runs',
       p.name_given,
       t.r_total
FROM totals t
JOIN max_vals m              ON t.r_total = m.max_r
JOIN player    p             ON p.player_id = t.player_id

UNION ALL
SELECT 'Hits',
       p.name_given,
       t.h_total
FROM totals t
JOIN max_vals m              ON t.h_total = m.max_h
JOIN player    p             ON p.player_id = t.player_id

UNION ALL
SELECT 'Home Runs',
       p.name_given,
       t.hr_total
FROM totals t
JOIN max_vals m              ON t.hr_total = m.max_hr
JOIN player    p             ON p.player_id = t.player_id
ORDER BY category, player_given_name;