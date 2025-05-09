WITH StyleScores AS (
    SELECT
        s."StyleName",
        SUM(
            CASE
                WHEN p."PreferenceSeq" = 1 THEN 3
                WHEN p."PreferenceSeq" = 2 THEN 2
                WHEN p."PreferenceSeq" = 3 THEN 1
                ELSE 0
            END
        ) AS "TotalWeightedScore"
    FROM
        "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_PREFERENCES" p
    JOIN
        "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_STYLES" s
        ON p."StyleID" = s."StyleID"
    WHERE
        p."PreferenceSeq" <= 3
    GROUP BY
        s."StyleName"
)
SELECT
    ss."StyleName",
    ss."TotalWeightedScore",
    ROUND(ABS(ss."TotalWeightedScore" - (SELECT AVG("TotalWeightedScore") FROM StyleScores)), 4) AS "AbsoluteDifferenceFromAverage"
FROM
    StyleScores ss
ORDER BY
    ss."StyleName";