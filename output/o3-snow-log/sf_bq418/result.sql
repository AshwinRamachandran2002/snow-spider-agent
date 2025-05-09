/*  Top-3 lowest-level Homo sapiens Reactome pathways (TAS evidence) that are
    most enriched for sorafenib targets whose experimental median ≤ 100 nM and
    low/high values ≤ 100 nM or NULL.                                       */

WITH
-- 1) Identify the Targetome drugID(s) for sorafenib
soraf_drug AS (
    SELECT DISTINCT "drugID"
    FROM   "TARGETOME_REACTOME"."TARGETOME_VERSIONED"."DRUG_SYNONYMS_V1"
    WHERE  LOWER("synonym") LIKE '%sorafenib%'
),

-- 2) Homo sapiens sorafenib interactions that pass the potency filters
soraf_interactions AS (
    SELECT DISTINCT i."target_uniprotID"
    FROM   "TARGETOME_REACTOME"."TARGETOME_VERSIONED"."INTERACTIONS_V1"  i
    JOIN   soraf_drug d                  ON i."drugID" = d."drugID"
    JOIN   "TARGETOME_REACTOME"."TARGETOME_VERSIONED"."EXPERIMENTS_V1" e
           ON i."expID" = e."expID"
    WHERE  i."targetSpecies" = 'Homo sapiens'
      AND  e."exp_assayValueMedian" IS NOT NULL
      AND  e."exp_assayValueMedian" <= 100
      AND (e."exp_assayValueLow"  IS NULL OR e."exp_assayValueLow"  <= 100)
      AND (e."exp_assayValueHigh" IS NULL OR e."exp_assayValueHigh" <= 100)
),

-- 3) Map those UniProt targets to Reactome Physical-Entity (PE) stable IDs
soraf_pe AS (
    SELECT DISTINCT p."stable_id" AS "pe_stable_id"
    FROM   "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PHYSICAL_ENTITY_V77" p
    JOIN   soraf_interactions s
           ON p."uniprot_id" = s."target_uniprotID"
),

-- 4) All PE–pathway pairs that have TAS evidence and are lowest-level,
--    Homo sapiens pathways (defines testing universe)
tas_hs_path_pe AS (
    SELECT DISTINCT
           pep."pathway_stable_id",
           pep."pe_stable_id"
    FROM   "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PE_TO_PATHWAY_V77" pep
    JOIN   "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PATHWAY_V77"  pw
           ON pw."stable_id" = pep."pathway_stable_id"
    WHERE  pep."evidence_code" = 'TAS'
      AND  pw."species"      = 'Homo sapiens'
      AND  pw."lowest_level" = TRUE
),

-- 5) Universe of PE IDs seen in step-4
universe_pe AS (
    SELECT DISTINCT "pe_stable_id"
    FROM   tas_hs_path_pe
),

-- 6) Grand totals needed for χ²
totals AS (
    SELECT
      (SELECT COUNT(*) FROM soraf_pe)    AS total_targets,
      (SELECT COUNT(*) FROM universe_pe) AS universe_size
),

-- 7) For every pathway, count sorafenib-target PEs (a) and non-target PEs (c)
contingencies AS (
    SELECT
        tp."pathway_stable_id"                            AS "pathway_id",
        COUNT(DISTINCT CASE WHEN tp."pe_stable_id" IN
                                 (SELECT "pe_stable_id" FROM soraf_pe)
                            THEN tp."pe_stable_id" END)   AS a,   -- targets in path
        COUNT(DISTINCT CASE WHEN tp."pe_stable_id" NOT IN
                                 (SELECT "pe_stable_id" FROM soraf_pe)
                            THEN tp."pe_stable_id" END)   AS c    -- non-targets in path
    FROM   tas_hs_path_pe tp
    GROUP BY tp."pathway_stable_id"
),

-- 8) χ² statistic for each pathway
chi2 AS (
    SELECT
        c."pathway_id",
        c.a,
        t.total_targets - c.a                               AS b,       -- targets outside path
        c.c,
        t.universe_size - t.total_targets - c.c             AS d,       -- non-targets outside path
        /* χ² = N(ad − bc)² / ((a+b)(c+d)(a+c)(b+d)) */
        t.universe_size *
        POWER( (c.a * (t.universe_size - t.total_targets - c.c) -
                (t.total_targets - c.a) * c.c), 2 )
        /
        NULLIF( (c.a + (t.total_targets - c.a)) *
                (c.c + (t.universe_size - t.total_targets - c.c)) *
                (c.a + c.c) *
                ((t.total_targets - c.a) +
                 (t.universe_size - t.total_targets - c.c)), 0 )        AS chi_squared
    FROM   contingencies c
    CROSS JOIN totals t
)

-- 9) Return the three pathways with the largest χ² values
SELECT
       chi."pathway_id",
       pw."name",
       chi.a AS "targets_in_path",
       chi.b AS "targets_outside_path",
       chi.c AS "non_targets_in_path",
       chi.d AS "non_targets_outside_path",
       chi.chi_squared
FROM   chi2 chi
JOIN   "TARGETOME_REACTOME"."REACTOME_VERSIONED"."PATHWAY_V77" pw
       ON pw."stable_id" = chi."pathway_id"
ORDER BY chi.chi_squared DESC NULLS LAST
LIMIT 3;