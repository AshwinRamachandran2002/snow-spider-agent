/*  Top-3 lowest-level Homo sapiens Reactome pathways (TAS evidence) that are
    most strongly enriched for Sorafenib targets (median / low / high ≤ 100 nM).
    The query returns, for each pathway, the 2 × 2 contingency-table counts:

       a = sorafenib-targets   inside pathway
       b = sorafenib-targets   outside pathway
       c = non-targets         inside pathway
       d = non-targets         outside pathway
*/
WITH
/*---------------------------------------------------------------------------
-- 1) Identify the Sorafenib drug-record (robust to naming differences)
---------------------------------------------------------------------------*/
drug AS (
    SELECT MIN("drugID") AS "drugID"
    FROM   TARGETOME_REACTOME.TARGETOME_VERSIONED."INTERACTIONS_V1"
    WHERE  LOWER("drugName") LIKE 'sorafenib%'
),
/*---------------------------------------------------------------------------
-- 2) Experiments that satisfy the 100 nM potency filter
---------------------------------------------------------------------------*/
potent_experiments AS (
    SELECT "expID"
    FROM   TARGETOME_REACTOME.TARGETOME_VERSIONED."EXPERIMENTS_V1"
    WHERE  "exp_assayValueMedian" <= 100
      AND ( "exp_assayValueLow"  <= 100 OR "exp_assayValueLow"  IS NULL )
      AND ( "exp_assayValueHigh" <= 100 OR "exp_assayValueHigh" IS NULL )
),
/*---------------------------------------------------------------------------
-- 3) Sorafenib-target interactions that meet the filter (Homo sapiens only)
---------------------------------------------------------------------------*/
soraf_interactions AS (
    SELECT  i."target_uniprotID"
    FROM    TARGETOME_REACTOME.TARGETOME_VERSIONED."INTERACTIONS_V1"  i
    JOIN    drug                    d  ON i."drugID" = d."drugID"
    JOIN    potent_experiments      e  ON i."expID"  = e."expID"
    WHERE   i."targetSpecies" = 'Homo sapiens'
),
/*---------------------------------------------------------------------------
-- 4) Map the qualified UniProt IDs to Reactome physical entities (PEs)
---------------------------------------------------------------------------*/
targets_pe AS (
    SELECT DISTINCT p."stable_id" AS "pe_stable_id"
    FROM   TARGETOME_REACTOME.REACTOME_VERSIONED."PHYSICAL_ENTITY_V77" p
    JOIN   soraf_interactions                s
           ON p."uniprot_id" = s."target_uniprotID"
),
/*---------------------------------------------------------------------------
-- 5) Background = all other Homo sapiens PEs (non-targets)
---------------------------------------------------------------------------*/
non_target_pe AS (
    SELECT DISTINCT p."stable_id" AS "pe_stable_id"
    FROM   TARGETOME_REACTOME.REACTOME_VERSIONED."PHYSICAL_ENTITY_V77" p
    WHERE  p."stable_id" NOT IN ( SELECT "pe_stable_id" FROM targets_pe )
),
/*---------------------------------------------------------------------------
-- 6) PE–to–pathway mappings supported by TAS evidence
---------------------------------------------------------------------------*/
pe_path_tas AS (
    SELECT  "pathway_stable_id",
            "pe_stable_id"
    FROM    TARGETOME_REACTOME.REACTOME_VERSIONED."PE_TO_PATHWAY_V77"
    WHERE   "evidence_code" = 'TAS'
),
/*---------------------------------------------------------------------------
-- 7) Count Sorafenib targets inside each pathway (a)
---------------------------------------------------------------------------*/
path_targets AS (
    SELECT  ppt."pathway_stable_id",
            COUNT(DISTINCT ppt."pe_stable_id") AS "a_in_path"
    FROM    pe_path_tas           ppt
    JOIN    targets_pe            tp  ON ppt."pe_stable_id" = tp."pe_stable_id"
    GROUP  BY ppt."pathway_stable_id"
),
/*---------------------------------------------------------------------------
-- 8) Count non-targets inside each pathway (c)
---------------------------------------------------------------------------*/
path_nontargets AS (
    SELECT  ppt."pathway_stable_id",
            COUNT(DISTINCT ppt."pe_stable_id") AS "c_in_path"
    FROM    pe_path_tas           ppt
    JOIN    non_target_pe         nt  ON ppt."pe_stable_id" = nt."pe_stable_id"
    GROUP  BY ppt."pathway_stable_id"
),
/*---------------------------------------------------------------------------
-- 9) Totals of targets and non-targets
---------------------------------------------------------------------------*/
totals AS (
    SELECT  (SELECT COUNT(*) FROM targets_pe)      AS "total_targets",
            (SELECT COUNT(*) FROM non_target_pe)   AS "total_nontargets"
),
/*---------------------------------------------------------------------------
-- 10) Assemble 2×2 table for every lowest-level Homo sapiens pathway
---------------------------------------------------------------------------*/
path_tables AS (
    SELECT
        pw."stable_id"                                           AS "pathway_id",
        COALESCE(pt."a_in_path", 0)                              AS "a",
        (t."total_targets"    - COALESCE(pt."a_in_path", 0))     AS "b",
        COALESCE(pn."c_in_path", 0)                              AS "c",
        (t."total_nontargets" - COALESCE(pn."c_in_path", 0))     AS "d"
    FROM   TARGETOME_REACTOME.REACTOME_VERSIONED."PATHWAY_V77" pw
    CROSS  JOIN totals                         t
    LEFT   JOIN path_targets                   pt ON pw."stable_id" = pt."pathway_stable_id"
    LEFT   JOIN path_nontargets                pn ON pw."stable_id" = pn."pathway_stable_id"
    WHERE  pw."lowest_level" = TRUE
      AND  pw."species"      = 'Homo sapiens'
),
/*---------------------------------------------------------------------------
-- 11) Compute chi-square statistic for each pathway
---------------------------------------------------------------------------*/
chi_squared AS (
    SELECT
        "pathway_id",
        "a","b","c","d",
        /* χ² = (N(ad − bc)²) / ((a+b)(c+d)(a+c)(b+d)) */
        CASE
            WHEN ("a"+"b")=0 OR ("c"+"d")=0 OR ("a"+"c")=0 OR ("b"+"d")=0
                 THEN NULL
            ELSE
                POWER(("a"* "d" - "b"* "c"), 2)
                * ("a"+"b"+"c"+"d")
                / ( ("a"+"b") * ("c"+"d") * ("a"+"c") * ("b"+"d") )
        END AS "chi_sq"
    FROM   path_tables
)
/*---------------------------------------------------------------------------
-- 12) Select the three pathways with the highest chi-square
---------------------------------------------------------------------------*/
SELECT
    "pathway_id"                          AS pathway_stable_id,
    "a"                                   AS targets_in_pathway,
    "b"                                   AS targets_outside_pathway,
    "c"                                   AS nontargets_in_pathway,
    "d"                                   AS nontargets_outside_pathway
FROM   chi_squared
ORDER BY "chi_sq" DESC NULLS LAST
LIMIT 3;