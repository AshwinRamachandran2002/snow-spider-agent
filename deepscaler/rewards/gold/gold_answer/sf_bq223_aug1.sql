-- Task: Find the titles of the primary CPC subclasses associated with the patents citing patents assigned to DENSO CORP. Provide the full title of the primary CPC subclass (based on the first CPC code) and the count of citations grouped by the CPC subclass title.
SELECT
    cpcdef."titleFull" AS cpc_title,
    COUNT(*) AS number
FROM (
    SELECT
        cite.value:"publication_number" AS cited_publication_number,
        SUBSTR(cpcs.value:"code", 1, 4) AS citing_cpc_subclass
    FROM 
        PATENTS.PATENTS.PUBLICATIONS AS pubs
        , LATERAL FLATTEN(input => pubs."citation") AS cite
        , LATERAL FLATTEN(input => pubs."cpc") AS cpcs
    WHERE
        cpcs.value:"first" = TRUE
) AS pubs
JOIN (
    SELECT
        "publication_number" AS cited_publication_number,
        cited_assignee_s.value:"name" AS cited_assignee
    FROM
        PATENTS.PATENTS.PUBLICATIONS
        , LATERAL FLATTEN(input => "assignee_harmonized") AS cited_assignee_s
) AS refs
    ON pubs.cited_publication_number = refs.cited_publication_number
JOIN
    PATENTS.PATENTS.CPC_DEFINITION AS cpcdef
    ON cpcdef."symbol" = pubs.citing_cpc_subclass
WHERE
    refs.cited_assignee = 'DENSO CORP'
GROUP BY
    cpcdef."titleFull"