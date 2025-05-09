/* ---------------------------------------------------------------
   Citing–cited network centred on DENSO patents
   ---------------------------------------------------------------
   Goal   :  For all patents that CITE at least one patent assigned
            to DENSO (with a valid filing date), list

               • the citing assignee (excluding any DENSO entity)
               • the full title of the primary CPC subclass
                 (based on the “first = true” CPC code, 4-digit level)
               • the number of such citation links

   Notes  :
     –  Only DENSO patents with a non-zero filing date are treated
        as “citable” targets.
     –  A primary CPC subclass is obtained by taking the first CPC
        code of the citing patent and truncating it to the first
        four characters (e.g. F02D41/1486  →  F02D).
     –  Counting unit = each distinct pair
            {citing publication  ×  cited-DENSO publication}.
        Duplicates arising from multiple “first” CPC codes or
        assignee repetitions are removed with DISTINCT.
   --------------------------------------------------------------- */
WITH denso_pubs AS (   ------------------------------------------------
    /* All DENSO-assigned publications with a valid filing date */
    SELECT DISTINCT
           p."publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS          p,
           LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE  p."filing_date" > 0
      AND  ah.value:"name"::STRING ILIKE '%denso%'
),

citing_events AS (     ------------------------------------------------
    /* One row per {citing pub, cited DENSO pub, assignee, CPC4}   */
    SELECT DISTINCT
           cp."publication_number"              AS "citing_pub",
           ca.value:"name"::STRING              AS "citing_assignee",
           SUBSTR(cc.value:"code"::STRING,1,4)  AS "cpc4",
           g.value:"publication_number"::STRING AS "cited_denso_pub"
    FROM   PATENTS.PATENTS.PUBLICATIONS  cp
           , LATERAL FLATTEN(input => cp."citation")            g
           , denso_pubs                                         dp
           , LATERAL FLATTEN(input => cp."assignee_harmonized") ca
           , LATERAL FLATTEN(input => cp."cpc")                 cc
    WHERE  g.value:"publication_number"::STRING = dp."publication_number"
      AND  cc.value:"first"::BOOLEAN = TRUE          -- primary CPC only
      AND  ca.value:"name"::STRING NOT ILIKE '%denso%'  -- exclude DENSO
)

SELECT
    ce."citing_assignee",
    cd."titleFull"               AS "cpc_subclass_title",
    COUNT(*)                     AS "citation_count"
FROM        citing_events              ce
JOIN        PATENTS.PATENTS.CPC_DEFINITION cd
       ON   cd."symbol" = ce."cpc4"
GROUP BY
    ce."citing_assignee",
    cd."titleFull"
ORDER BY
    "citation_count" DESC NULLS LAST;