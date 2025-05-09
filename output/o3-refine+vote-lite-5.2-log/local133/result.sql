WITH pref_scores AS (
    /* 1.  Calculate the weighted score for every style that appears in Musical_Preferences */
    SELECT
        "StyleID",
        SUM(CASE "PreferenceSeq"
                WHEN 1 THEN 3   /* first‑choice ⇒ 3 points */
                WHEN 2 THEN 2   /* second‑choice ⇒ 2 points */
                WHEN 3 THEN 1   /* third‑choice  ⇒ 1 point  */
                ELSE 0
            END) AS "TotalScore"
    FROM "Musical_Preferences"
    GROUP BY "StyleID"
)
SELECT
    ps."StyleID",
    ms."StyleName",
    ps."TotalScore",
    /* 2.  Compare each style’s score to the average of all scored styles */
    ABS(
        ps."TotalScore" -
        (SELECT AVG("TotalScore") FROM pref_scores)   /* average weighted score */
    ) AS "DifferenceFromAverage"
FROM pref_scores AS ps
LEFT JOIN "Musical_Styles" AS ms
       ON ms."StyleID" = ps."StyleID"
ORDER BY ps."StyleID";