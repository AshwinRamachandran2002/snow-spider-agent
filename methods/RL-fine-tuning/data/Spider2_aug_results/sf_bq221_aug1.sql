-- Task: For each CPC group, get the total number of patents filed each year, considering only the first CPC code for each patent with a valid filing date and a non-empty application number, and report the CPC group along with the filing year and the patent count. Limit the results to 100 rows.

WITH patent_cpcs AS (
    SELECT
        cd."parents",
        CAST(FLOOR("filing_date" / 10000) AS INT) AS "filing_year"
    FROM (
        SELECT
            MAX("cpc") AS "cpc", MAX("filing_date") AS "filing_date"
        FROM
            "PATENTS"."PATENTS"."PUBLICATIONS"
        WHERE 
            "application_number" != ''
        GROUP BY
            "application_number"
    ) AS publications,
    LATERAL FLATTEN(INPUT => "cpc") AS cpcs
    JOIN
        "PATENTS"."PATENTS"."CPC_DEFINITION" cd ON cd."symbol" = cpcs.value:"code"
    WHERE 
        cpcs.value:"first" = TRUE
        AND "filing_date" > 0
)
SELECT
    cpc_parent.value::STRING AS "cpc_group",
    "filing_year",
    COUNT(*) AS "cnt"
FROM patent_cpcs,
     LATERAL FLATTEN(input => patent_cpcs."parents") AS cpc_parent
GROUP BY
    "cpc_group",
    "filing_year"
ORDER BY
    "cpc_group",
    "filing_year"
LIMIT 100;