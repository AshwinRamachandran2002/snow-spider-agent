SELECT 
    p."publication_number",
    COUNT(c.value) AS "sea_backward_citation_count"
FROM 
    PATENTS.PATENTS.PUBLICATIONS AS p,
    LATERAL FLATTEN(input => p."citation") AS c
WHERE 
    p."grant_date" BETWEEN 20100101 AND 20181231
    AND c.value:"category"::string = 'SEA'          -- keep only SEA‑category citations
GROUP BY 
    p."publication_number"
ORDER BY 
    "sea_backward_citation_count" DESC NULLS LAST,
    p."publication_number";