SELECT
    cc."Chr" AS Chromosome,
    cc."Type" AS Aberration_type,
    COUNT(DISTINCT c."RefNo" || '-' || c."CaseNo") AS Num_Cases,
    ROUND((COUNT(DISTINCT c."RefNo" || '-' || c."CaseNo")::FLOAT / total_cases.total_cases), 4) AS Frequency
FROM
    MITELMAN.PROD.CYTOCONVERTED cc
JOIN
    MITELMAN.PROD.CYTOGEN c
    ON c."RefNo" = cc."RefNo" AND c."CaseNo" = cc."CaseNo"
CROSS JOIN
    (
        SELECT COUNT(DISTINCT c2."RefNo" || '-' || c2."CaseNo") AS total_cases
        FROM MITELMAN.PROD.CYTOGEN c2
        WHERE c2."Morph" = '3111' AND c2."Topo" = '0401'
    ) total_cases
WHERE
    c."Morph" = '3111' AND c."Topo" = '0401'
    AND cc."Type" IN ('Gain', 'Loss', 'Amplification', 'Deletion')
GROUP BY
    cc."Chr",
    cc."Type",
    total_cases.total_cases
HAVING
    COUNT(DISTINCT c."RefNo" || '-' || c."CaseNo") >= 5
ORDER BY
    Chromosome,
    Aberration_type;