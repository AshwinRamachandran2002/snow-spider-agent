/* -------------------------------------------------------------------------
   1)  denso_patents   : list of DENSO-assigned patents having a valid filing
                         date (set of publication_numbers to be cited).
   2)  citing_filtered : patents that (a) are NOT assigned to DENSO,
                         (b) have a valid filing date, and (c) actually cite
                         one of the DENSO patents (checked while flattening
                         the citation array).   This drastically reduces the
                         data volume carried forward.
   3)  Final SELECT    : for every citing patent obtained in (2) we keep the
                         first / primary CPC code (cp.index = 0) and fetch
                         its full subclass title from CPC_DEFINITION.  We then
                         count distinct citing publications per
                         (assignee × CPC-title).
--------------------------------------------------------------------------- */
WITH denso_patents AS (          -- ❶ DENSO patents (to be cited)
    SELECT DISTINCT
           p."publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS p
    WHERE  p."assignee_harmonized" ILIKE '%DENSO%CORP%'
      AND  p."filing_date" IS NOT NULL
),

citing_filtered AS (             -- ❷ Non-DENSO patents that cite a DENSO patent
    SELECT DISTINCT
           cr."publication_number",
           cr."assignee_harmonized",
           cr."cpc"
    FROM   PATENTS.PATENTS.PUBLICATIONS cr,
           LATERAL FLATTEN(input => cr."citation") f
    WHERE  cr."filing_date" IS NOT NULL
      AND  cr."assignee_harmonized" NOT ILIKE '%DENSO%CORP%'
      AND  f.value:"publication_number"::STRING IN (SELECT "publication_number"
                                                    FROM   denso_patents)
)

SELECT
    cf."assignee_harmonized"::STRING                AS "citing_assignee",
    def."titleFull"                                 AS "cpc_title",
    COUNT(DISTINCT cf."publication_number")         AS "citation_count"
FROM   citing_filtered cf
       , LATERAL FLATTEN(input => cf."cpc")  cp
       , PATENTS.PATENTS.CPC_DEFINITION      def
WHERE  cp.index = 0                                    -- primary CPC only
  AND  def."symbol" = cp.value:"code"::STRING          -- fetch CPC title
GROUP BY
       cf."assignee_harmonized"::STRING,
       def."titleFull"
ORDER BY
       "citation_count" DESC NULLS LAST;