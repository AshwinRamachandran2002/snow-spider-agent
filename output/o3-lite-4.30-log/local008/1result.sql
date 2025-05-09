WITH max_vals AS (
    SELECT 'games'      AS statistic, MAX(CAST(g  AS INTEGER))  AS max_value FROM batting WHERE g  <> '' AND g  IS NOT NULL
    UNION ALL
    SELECT 'runs',                MAX(CAST(r  AS INTEGER))                FROM batting WHERE r  <> '' AND r  IS NOT NULL
    UNION ALL
    SELECT 'hits',                MAX(CAST(h  AS INTEGER))                FROM batting WHERE h  <> '' AND h  IS NOT NULL
    UNION ALL
    SELECT 'home_runs',           MAX(CAST(hr AS INTEGER))                FROM batting WHERE hr <> '' AND hr IS NOT NULL
),
record_holders AS (
    SELECT DISTINCT p.name_given AS given_name, 'games' AS statistic, m.max_value
    FROM batting b
    JOIN player  p ON p.player_id = b.player_id
    JOIN max_vals m ON m.statistic = 'games'
    WHERE CAST(b.g AS INTEGER) = m.max_value

    UNION ALL
    SELECT DISTINCT p.name_given, 'runs', m.max_value
    FROM batting b
    JOIN player  p ON p.player_id = b.player_id
    JOIN max_vals m ON m.statistic = 'runs'
    WHERE CAST(b.r AS INTEGER) = m.max_value

    UNION ALL
    SELECT DISTINCT p.name_given, 'hits', m.max_value
    FROM batting b
    JOIN player  p ON p.player_id = b.player_id
    JOIN max_vals m ON m.statistic = 'hits'
    WHERE CAST(b.h AS INTEGER) = m.max_value

    UNION ALL
    SELECT DISTINCT p.name_given, 'home_runs', m.max_value
    FROM batting b
    JOIN player  p ON p.player_id = b.player_id
    JOIN max_vals m ON m.statistic = 'home_runs'
    WHERE CAST(b.hr AS INTEGER) = m.max_value
)
SELECT given_name, statistic, max_value
FROM record_holders
ORDER BY statistic, given_name;