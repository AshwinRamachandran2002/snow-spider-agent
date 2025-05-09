WITH TotalCases AS (
    SELECT COUNT(DISTINCT CONCAT(c."RefNo", '-', c."CaseNo")) AS TotalCases
    FROM "MITELMAN"."PROD"."CYTOGEN" c
    WHERE c."Morph" = '3111' AND c."Topo" = '0401'
),
AberrationFrequencies AS (
    SELECT
        cc."Chr" AS Chromosome,
        cc."Type" AS Aberration_Type,
        COUNT(DISTINCT CONCAT(cc."RefNo", '-', cc."CaseNo")) AS NumCasesWithAberration,
        ROUND((COUNT(DISTINCT CONCAT(cc."RefNo", '-', cc."CaseNo")) * 100.0) / (SELECT TotalCases FROM TotalCases), 4) AS Frequency_Percentage
    FROM "MITELMAN"."PROD"."CYTOCONVERTED" cc
    JOIN "MITELMAN"."PROD"."CYTOGEN" c
        ON cc."RefNo" = c."RefNo" AND cc."CaseNo" = c."CaseNo"
    WHERE c."Morph" = '3111' AND c."Topo" = '0401'
    GROUP BY cc."Chr", cc."Type"
    HAVING COUNT(DISTINCT CONCAT(cc."RefNo", '-', cc."CaseNo")) >= 5
)
SELECT Chromosome, Aberration_Type, NumCasesWithAberration, Frequency_Percentage
FROM AberrationFrequencies
ORDER BY Chromosome, Aberration_Type;