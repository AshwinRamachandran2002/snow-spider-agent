-- Compute the frequency of copy number aberrations per chromosome and aberration type from the Mitelman database for cases with Morph = '3111' and Topo = '0401'

WITH
-- Total number of Mitelman cases with Morph = '3111' and Topo = '0401'
mitelman_total_cases AS (
    SELECT COUNT(DISTINCT CONCAT(cg."RefNo", '_', cg."CaseNo")) AS "Total_cases"
    FROM MITELMAN.PROD.CYTOGEN cg
    WHERE cg."Morph" = '3111' AND cg."Topo" = '0401'
),

-- Mitelman frequencies per chromosome and aberration type
mitelman_frequencies AS (
    SELECT
        cc."Chr" AS "Chromosome",
        cc."Type" AS "Aberration_type",
        COUNT(DISTINCT CONCAT(cc."RefNo", '_', cc."CaseNo")) AS "Aberration_case_count",
        mtc."Total_cases",
        COUNT(DISTINCT CONCAT(cc."RefNo", '_', cc."CaseNo"))::FLOAT / mtc."Total_cases" AS "Frequency"
    FROM
        MITELMAN.PROD.CYTOCONVERTED cc
    INNER JOIN
        MITELMAN.PROD.CYTOGEN cg
        ON cc."RefNo" = cg."RefNo" AND cc."CaseNo" = cg."CaseNo"
    CROSS JOIN
        mitelman_total_cases mtc
    WHERE
        cg."Morph" = '3111' AND cg."Topo" = '0401'
    GROUP BY
        cc."Chr", cc."Type", mtc."Total_cases"
    HAVING
        COUNT(DISTINCT CONCAT(cc."RefNo", '_', cc."CaseNo")) >= 5
)
SELECT
    "Chromosome",
    "Aberration_type",
    "Aberration_case_count",
    "Total_cases",
    ROUND("Frequency", 4) AS "Frequency"
FROM
    mitelman_frequencies
ORDER BY
    "Aberration_type", "Chromosome";