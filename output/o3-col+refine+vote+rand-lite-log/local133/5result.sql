SELECT  s."StyleID",
        ms."StyleName",
        s."WeightedScore",
        ABS(s."WeightedScore" - a."AvgWeightedScore") AS "DiffFromAverage"
FROM   (
        /* 1.  Compute each style’s weighted score (3-2-1 system) */
        SELECT  "StyleID",
                3 * SUM(CASE WHEN "PreferenceSeq" = 1 THEN 1 ELSE 0 END) +
                2 * SUM(CASE WHEN "PreferenceSeq" = 2 THEN 1 ELSE 0 END) +
                1 * SUM(CASE WHEN "PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "WeightedScore"
        FROM    "Musical_Preferences"
        GROUP BY "StyleID"
       ) AS s
       /* 2.  Overall average of those weighted scores */
CROSS JOIN
       (
        SELECT  AVG("WeightedScore") AS "AvgWeightedScore"
        FROM   (
                SELECT  3 * SUM(CASE WHEN "PreferenceSeq" = 1 THEN 1 ELSE 0 END) +
                        2 * SUM(CASE WHEN "PreferenceSeq" = 2 THEN 1 ELSE 0 END) +
                        1 * SUM(CASE WHEN "PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "WeightedScore"
                FROM    "Musical_Preferences"
                GROUP BY "StyleID"
               )
       ) AS a
       /* 3.  Attach the human-readable style name */
JOIN   "Musical_Styles" AS ms
       ON ms."StyleID" = s."StyleID"
ORDER BY s."StyleID";