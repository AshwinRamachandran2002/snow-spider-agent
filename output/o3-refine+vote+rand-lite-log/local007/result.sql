WITH career_spans AS (
    SELECT
        player_id,
        -- difference components
        ABS(CAST(substr("final_game",1,4) AS INTEGER) - CAST(substr("debut",1,4) AS INTEGER))  AS yr_diff,
        ABS(CAST(substr("final_game",6,2) AS INTEGER) - CAST(substr("debut",6,2) AS INTEGER))  AS mo_diff,
        ABS(CAST(substr("final_game",9,2) AS INTEGER) - CAST(substr("debut",9,2) AS INTEGER))  AS day_diff
    FROM player
    WHERE "debut"      IS NOT NULL AND "final_game" IS NOT NULL
      AND "debut"      <> ''        AND "final_game" <> ''
      AND length("debut") = 10      AND length("final_game") = 10   -- ensure YYYY-MM-DD form
), span_calculated AS (
    SELECT
        player_id,
        ROUND(yr_diff,2)                                                           AS years_part,
        ROUND(mo_diff/12.0,2)                                                      AS months_part,
        ROUND(day_diff/365.0,2)                                                    AS days_part,
        ROUND(yr_diff,2) + ROUND(mo_diff/12.0,2) + ROUND(day_diff/365.0,2)         AS career_span
    FROM career_spans
)
SELECT ROUND(AVG(career_span),4) AS average_single_career_span
FROM span_calculated;