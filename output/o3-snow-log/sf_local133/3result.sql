WITH STYLE_SCORES AS (
    /* 1.  Calculate the weighted score (3/2/1) for each style that appears
          in the MUSICAL_PREFERENCES table                                       */
    SELECT 
        "StyleID",
        SUM(
            CASE "PreferenceSeq"
                 WHEN 1 THEN 3      -- first-choice
                 WHEN 2 THEN 2      -- second-choice
                 WHEN 3 THEN 1      -- third-choice
                 ELSE 0             -- ignore any other ranking values
            END
        )   AS TOTAL_SCORE
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    GROUP BY "StyleID"
)

SELECT
    ss."StyleID",
    ms."StyleName",
    ss.TOTAL_SCORE,
    /* 2.  Average total score across all ranked styles                         */
    AVG(ss.TOTAL_SCORE) OVER ()                                          AS AVG_TOTAL_SCORE,
    /* 3.  Absolute difference from the average                                */
    ABS(ss.TOTAL_SCORE - AVG(ss.TOTAL_SCORE) OVER ())                    AS ABS_DIFF_FROM_AVG
FROM STYLE_SCORES ss
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_STYLES ms
  ON ss."StyleID" = ms."StyleID"
ORDER BY ABS_DIFF_FROM_AVG DESC NULLS LAST;