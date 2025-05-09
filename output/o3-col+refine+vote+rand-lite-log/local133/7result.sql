SELECT  ms."StyleID",
        ms."StyleName",
        t."TotalWeightedScore",
        ABS(t."TotalWeightedScore" - a."AvgWeightedScore") AS "DifferenceToAvg"
FROM   (
        SELECT  "StyleID",
                SUM(CASE "PreferenceSeq"
                        WHEN 1 THEN 3
                        WHEN 2 THEN 2
                        WHEN 3 THEN 1
                    END) AS "TotalWeightedScore"
        FROM    "Musical_Preferences"
        GROUP BY "StyleID"
       ) AS t
JOIN   "Musical_Styles" ms ON ms."StyleID" = t."StyleID"
CROSS JOIN (
            SELECT AVG("TotalWeightedScore") AS "AvgWeightedScore"
            FROM  (
                   SELECT  "StyleID",
                           SUM(CASE "PreferenceSeq"
                                   WHEN 1 THEN 3
                                   WHEN 2 THEN 2
                                   WHEN 3 THEN 1
                               END) AS "TotalWeightedScore"
                   FROM    "Musical_Preferences"
                   GROUP BY "StyleID"
                  )
           ) AS a
ORDER BY "DifferenceToAvg" DESC;