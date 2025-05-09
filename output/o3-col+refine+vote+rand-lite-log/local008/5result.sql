WITH max_vals AS (
    SELECT
        MAX(CAST(g  AS INTEGER))  AS max_g,
        MAX(CAST(r  AS INTEGER))  AS max_r,
        MAX(CAST(h  AS INTEGER))  AS max_h,
        MAX(CAST(hr AS INTEGER))  AS max_hr
    FROM batting
    WHERE g  IS NOT NULL AND g  <> ''
       OR r  IS NOT NULL AND r  <> ''
       OR h  IS NOT NULL AND h  <> ''
       OR hr IS NOT NULL AND hr <> ''
),
records AS (
    /* Games-played record holders */
    SELECT b.player_id,
           CAST(b.g AS INTEGER)  AS record_value,
           'Games Played'        AS record_type
    FROM batting b, max_vals
    WHERE CAST(b.g AS INTEGER) = max_vals.max_g

    UNION ALL
    /* Runs record holders */
    SELECT b.player_id,
           CAST(b.r AS INTEGER),
           'Runs'
    FROM batting b, max_vals
    WHERE CAST(b.r AS INTEGER) = max_vals.max_r

    UNION ALL
    /* Hits record holders */
    SELECT b.player_id,
           CAST(b.h AS INTEGER),
           'Hits'
    FROM batting b, max_vals
    WHERE CAST(b.h AS INTEGER) = max_vals.max_h

    UNION ALL
    /* Home-run record holders */
    SELECT b.player_id,
           CAST(b.hr AS INTEGER),
           'Home Runs'
    FROM batting b, max_vals
    WHERE CAST(b.hr AS INTEGER) = max_vals.max_hr
)
SELECT DISTINCT
       p.name_given,
       r.record_value,
       r.record_type
FROM records r
JOIN player p ON p.player_id = r.player_id
ORDER BY r.record_type, p.name_given;