SELECT
    "publication_number",
    COUNT(*) AS "sea_backward_citation_count"
FROM
    PATENTS.PATENTS.PUBLICATIONS
    , LATERAL FLATTEN(input => "citation") f          -- expand each citation
WHERE
    "grant_date" BETWEEN 20100101 AND 20181231        -- patents granted 2010-2018
    AND f.value:"category"::STRING = 'SEA'            -- keep SEA-category citations
GROUP BY
    "publication_number";