WITH totals AS (
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
    FROM totals
),
leaders AS (
    SELECT 'Games Played' AS stat, player_id, total_g AS value
    FROM totals, max_vals
    WHERE total_g = max_g

    UNION ALL
    SELECT 'Runs' AS stat, player_id, total_r
    FROM totals, max_vals
    WHERE total_r = max_r

    UNION ALL
    SELECT 'Hits' AS stat, player_id, total_h
    FROM totals, max_vals
    WHERE total_h = max_h

    UNION ALL
    SELECT 'Home Runs' AS stat, player_id, total_hr
    FROM totals, max_vals
    WHERE total_hr = max_hr
)
SELECT 
    stat,
    p.name_given AS given_name,
    value AS score_value
FROM leaders l
JOIN player p ON p.player_id = l.player_id
ORDER BY stat, given_name;