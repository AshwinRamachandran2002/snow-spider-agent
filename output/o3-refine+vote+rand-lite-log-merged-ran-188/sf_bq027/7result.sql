SELECT
    p."publication_number",
    SUM(
        CASE 
            WHEN c.value:"category"::STRING = 'SEA' THEN 1 
            ELSE 0 
        END
    ) AS "sea_backward_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS AS p
CROSS JOIN LATERAL FLATTEN(
        INPUT => p."citation",
        OUTER => TRUE        -- keeps publications with no citations
) AS c
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
GROUP BY p."publication_number"
ORDER BY p."publication_number";