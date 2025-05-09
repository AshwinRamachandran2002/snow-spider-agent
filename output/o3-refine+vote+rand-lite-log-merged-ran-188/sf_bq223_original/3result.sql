/* -------------------------------------------------------------------------
   Citing–cited network                                      Snowflake SQL
   -------------------------------------------------------------------------
   Goal :  For every patent that CITES a patent assigned to DENSO CORP,
           return (i) the citing assignee (≠ DENSO CORP),
           (ii) the full title of the PRIMARY CPC subclass
                (taken from the first CPC code of the citing patent) and
           (iii) the number of such citations.
   ----------------------------------------------------------------------- */

WITH denso_pubs AS (            -- 1.  All publications whose assignee = DENSO
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN( INPUT => p."assignee_harmonized" ) f
    WHERE UPPER(f.value:name::string) LIKE 'DENSO%'
),

citing_relations AS (           -- 2.  Each individual citation TO a DENSO patent
    SELECT
        cp."publication_number"              AS citing_pub ,
        cit.value:publication_number::string AS cited_pub
    FROM PATENTS.PATENTS.PUBLICATIONS cp,
         LATERAL FLATTEN( INPUT => cp."citation" ) cit
    WHERE cit.value:publication_number::string IN ( SELECT "publication_number" FROM denso_pubs )
      AND cp."filing_date" IS NOT NULL
      AND cp."filing_date" > 0
),

citing_pubs AS (                -- 3.  Distinct citing publication numbers
    SELECT DISTINCT citing_pub FROM citing_relations
),

primary_cpc AS (                -- 4.  Primary CPC subclass (first code) of each citing pub
    SELECT
        cp."publication_number"                         AS citing_pub ,
        SUBSTR(cpc.value:code::string, 1, 4)            AS cpc_subclass
    FROM PATENTS.PATENTS.PUBLICATIONS cp
         JOIN citing_pubs cpb
           ON cp."publication_number" = cpb.citing_pub
         ,  LATERAL FLATTEN( INPUT => cp."cpc" ) cpc
    WHERE cpc.value:first::boolean = TRUE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY cp."publication_number" ORDER BY cp."publication_number") = 1
),

citing_assignees AS (           -- 5.  All non‑DENSO assignees of the citing pubs
    SELECT DISTINCT
        cp."publication_number"            AS citing_pub ,
        ass.value:name::string             AS citing_assignee
    FROM PATENTS.PATENTS.PUBLICATIONS cp
         JOIN citing_pubs cpb
           ON cp."publication_number" = cpb.citing_pub
         ,  LATERAL FLATTEN( INPUT => cp."assignee_harmonized" ) ass
    WHERE UPPER(ass.value:name::string) NOT LIKE 'DENSO%'
),

final_counts AS (               -- 6.  Combine everything and count citations
    SELECT
        ca.citing_assignee                              AS assignee_name ,
        COALESCE(cd."titleFull", 'UNKNOWN')             AS primary_cpc_subclass_title ,
        COUNT(*)                                        AS citation_count
    FROM citing_relations            rel
         JOIN citing_assignees       ca  ON rel.citing_pub = ca.citing_pub
         LEFT JOIN primary_cpc       pc  ON rel.citing_pub = pc.citing_pub
         LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
                ON cd."symbol" = pc.cpc_subclass
    GROUP BY
        ca.citing_assignee,
        COALESCE(cd."titleFull", 'UNKNOWN')
)

SELECT
    assignee_name               AS "ASSIGNEE_NAME",
    primary_cpc_subclass_title  AS "PRIMARY_CPC_SUBCLASS_TITLE",
    citation_count              AS "CITATION_COUNT"
FROM final_counts
ORDER BY citation_count DESC NULLS LAST,
         assignee_name,
         primary_cpc_subclass_title;