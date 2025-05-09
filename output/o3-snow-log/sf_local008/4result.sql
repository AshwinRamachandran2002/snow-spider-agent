WITH stats AS (   -- convert needed stats to numeric form
    SELECT
        "PLAYER_ID",
        "G"                                        AS G_INT,
        TRY_TO_NUMBER("R")                         AS R_INT,
        TRY_TO_NUMBER("H")                         AS H_INT,
        TRY_TO_NUMBER("HR")                        AS HR_INT
    FROM BASEBALL.BASEBALL.BATTING
),
max_vals AS (      -- overall maxima
    SELECT
        MAX(G_INT)  AS MAX_G,
        MAX(R_INT)  AS MAX_R,
        MAX(H_INT)  AS MAX_H,
        MAX(HR_INT) AS MAX_HR
    FROM stats
),
top_g AS (
    SELECT "PLAYER_ID", G_INT  AS VALUE, 'GAMES_PLAYED' AS METRIC
    FROM stats, max_vals
    WHERE G_INT = MAX_G
),
top_r AS (
    SELECT "PLAYER_ID", R_INT  AS VALUE, 'RUNS'         AS METRIC
    FROM stats, max_vals
    WHERE R_INT = MAX_R
),
top_h AS (
    SELECT "PLAYER_ID", H_INT  AS VALUE, 'HITS'         AS METRIC
    FROM stats, max_vals
    WHERE H_INT = MAX_H
),
top_hr AS (
    SELECT "PLAYER_ID", HR_INT AS VALUE, 'HOME_RUNS'    AS METRIC
    FROM stats, max_vals
    WHERE HR_INT = MAX_HR
),
combined AS (      -- gather all leader rows
    SELECT * FROM top_g
    UNION ALL
    SELECT * FROM top_r
    UNION ALL
    SELECT * FROM top_h
    UNION ALL
    SELECT * FROM top_hr
)

SELECT
    p."NAME_GIVEN"           AS GIVEN_NAME,
    c.METRIC,
    c.VALUE
FROM combined c
JOIN BASEBALL.BASEBALL.PLAYER p
      ON p."PLAYER_ID" = c."PLAYER_ID"
ORDER BY
    c.METRIC,
    GIVEN_NAME;