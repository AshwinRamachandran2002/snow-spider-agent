WITH DENSO_PUBS AS (
    SELECT DISTINCT t1."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS t1,
         LATERAL FLATTEN(input => t1."assignee_harmonized") assignee
    WHERE assignee.value:"name"::STRING = 'DENSO CORP'
),
CITING_PUBS AS (
    SELECT DISTINCT t2."publication_number" AS citing_publication_number
    FROM PATENTS.PATENTS.PUBLICATIONS t2,
         LATERAL FLATTEN(input => t2."citation") c2
    WHERE c2.value:"publication_number"::STRING IN (SELECT "publication_number" FROM DENSO_PUBS)
),
CITING_PUBS_WITH_ASSIGNEE AS (
    SELECT DISTINCT cp.citing_publication_number, assignee.value:"name"::STRING AS assignee_name
    FROM CITING_PUBS cp
    JOIN PATENTS.PATENTS.PUBLICATIONS t2 ON t2."publication_number" = cp.citing_publication_number
    , LATERAL FLATTEN(input => t2."assignee_harmonized") assignee
    WHERE assignee.value:"name"::STRING != 'DENSO CORP'
),
CITING_PUBS_WITH_CPC AS (
    SELECT cpwa.citing_publication_number, cpwa.assignee_name, SUBSTR(cpc.value:"code"::STRING,1,1) AS cpc_main_category
    FROM CITING_PUBS_WITH_ASSIGNEE cpwa
    JOIN PATENTS.PATENTS.PUBLICATIONS t2 ON t2."publication_number" = cpwa.citing_publication_number
    , LATERAL FLATTEN(input => t2."cpc") cpc
)
SELECT cpwc.assignee_name AS Assignee, def."titleFull" AS CPC_Subclass_Title, COUNT(DISTINCT cpwc.citing_publication_number) AS Citation_Count
FROM CITING_PUBS_WITH_CPC cpwc
JOIN PATENTS.PATENTS.CPC_DEFINITION def ON cpwc.cpc_main_category = def."symbol"
GROUP BY cpwc.assignee_name, def."titleFull"
ORDER BY Citation_Count DESC NULLS LAST;