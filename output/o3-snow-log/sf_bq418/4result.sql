/*───────────────────────────────────────────────────────────────────────────────
   Top-3 lowest-level Reactome pathways (TAS evidence) that are most enriched
   for potency-qualified Homo sapiens sorafenib targets.
───────────────────────────────────────────────────────────────────────────────*/
WITH
/* 1 ─ Sorafenib targets that satisfy potency filter (≤100 nM) */
soraf_targets AS (
    SELECT DISTINCT i."target_uniprotID"
    FROM   TARGETOME_REACTOME.TARGETOME_VERSIONED."INTERACTIONS_V1"  i
    JOIN   TARGETOME_REACTOME.TARGETOME_VERSIONED."EXPERIMENTS_V1"   e
           ON i."expID" = e."expID"
    WHERE  i."drugName" ILIKE '%sorafenib%'
      AND  i."targetSpecies" = 'Homo sapiens'
      AND  e."exp_assayValueMedian" IS NOT NULL
      AND  e."exp_assayValueMedian" <= 100
      AND (e."exp_assayValueLow"  IS NULL OR e."exp_assayValueLow"  <= 100)
      AND (e."exp_assayValueHigh" IS NULL OR e."exp_assayValueHigh" <= 100)
),
/* 2 ─ Map those targets to Reactome physical entities (PEs) */
target_pes AS (
    SELECT DISTINCT p."stable_id" AS "pe_stable_id"
    FROM   TARGETOME_REACTOME.REACTOME_VERSIONED."PHYSICAL_ENTITY_V77" p
    JOIN   soraf_targets t
           ON p."uniprot_id" = t."target_uniprotID"
),
/* 3 ─ All lowest-level TAS pathways and their PEs */
lowest_lvl_tas AS (
    SELECT
        pw."stable_id"    AS pathway_id,
        pw."name"         AS pathway_name,
        m."pe_stable_id"  AS pe_stable_id
    FROM   TARGETOME_REACTOME.REACTOME_VERSIONED."PATHWAY_V77"        pw
    JOIN   TARGETOME_REACTOME.REACTOME_VERSIONED."PE_TO_PATHWAY_V77"  m
           ON m."pathway_stable_id" = pw."stable_id"
    WHERE  pw."lowest_level" = TRUE
      AND  m."evidence_code" = 'TAS'
),
/* 4 ─ Per-pathway counts of PEs and of sorafenib-target PEs */
pathway_pe_counts AS (
    SELECT
        l.pathway_id,
        l.pathway_name,
        COUNT(DISTINCT l.pe_stable_id)                                   AS pes_in,
        COUNT(DISTINCT CASE WHEN tp."pe_stable_id" IS NOT NULL
                             THEN l.pe_stable_id END)                   AS targets_in
    FROM   lowest_lvl_tas l
    LEFT  JOIN target_pes tp
           ON l.pe_stable_id = tp."pe_stable_id"
    GROUP BY l.pathway_id, l.pathway_name
),
/* 5 ─ Global totals required for χ² calculation */
globals AS (
    SELECT
        (SELECT COUNT(DISTINCT pe_stable_id) FROM lowest_lvl_tas) AS total_pes,
        (SELECT COUNT(DISTINCT "pe_stable_id") FROM target_pes)   AS total_targets
),
/* 6 ─ Build 2×2 contingency tables and compute χ² for each pathway */
chi2 AS (
    SELECT
        pc.pathway_id  AS pathway_stable_id,
        pc.pathway_name,
        pc.targets_in                                           AS targets_in_pathway,         -- A
        pc.pes_in - pc.targets_in                               AS non_targets_in_pathway,     -- C
        g.total_targets - pc.targets_in                         AS targets_outside_pathway,    -- B
        (g.total_pes - g.total_targets)
          - (pc.pes_in - pc.targets_in)                         AS non_targets_outside_pathway,-- D
        /* χ² = N(AD−BC)² / (R1·R2·C1·C2) */
        (
            g.total_pes
            * POWER(
                  pc.targets_in *
                  ( (g.total_pes - g.total_targets) - (pc.pes_in - pc.targets_in) )
                - (g.total_targets - pc.targets_in) *
                  (pc.pes_in - pc.targets_in),
              2)
        )
        / NULLIF(
              g.total_targets
              * (g.total_pes - g.total_targets)
              * pc.pes_in
              * (g.total_pes - pc.pes_in),
            0)                                                  AS chi_squared
    FROM pathway_pe_counts pc
    CROSS JOIN globals g
)
/* 7 ─ Return the three pathways with the highest χ² values */
SELECT
    pathway_stable_id,
    pathway_name,
    targets_in_pathway,
    non_targets_in_pathway,
    targets_outside_pathway,
    non_targets_outside_pathway
FROM   chi2
ORDER BY chi_squared DESC NULLS LAST
LIMIT 3;