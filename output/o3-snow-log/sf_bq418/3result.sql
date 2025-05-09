WITH
/* 1.  Sorafenib (drugID = 157) Homo-sapiens targets that meet the potency criteria */
sorafenib_targets AS (
    SELECT DISTINCT i."target_uniprotID"
    FROM TARGETOME_REACTOME.TARGETOME_VERSIONED.INTERACTIONS_V1  i
    JOIN TARGETOME_REACTOME.TARGETOME_VERSIONED.EXPERIMENTS_V1   e
          ON i."expID" = e."expID"
    WHERE i."drugID" = 157
      AND i."targetSpecies" ILIKE '%Homo sapiens%'
      AND COALESCE(e."exp_assayValueMedian", 1e9) <= 100
      AND (e."exp_assayValueLow"  <= 100 OR e."exp_assayValueLow"  IS NULL)
      AND (e."exp_assayValueHigh" <= 100 OR e."exp_assayValueHigh" IS NULL)
),
/* 2.  Map those targets to Reactome physical entities */
sorafenib_pe AS (
    SELECT DISTINCT p."stable_id" AS "pe_stable_id"
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PHYSICAL_ENTITY_V77 p
    JOIN sorafenib_targets t
      ON p."uniprot_id" = t."target_uniprotID"
),
/* 3.  TAS-supported PE ↔ pathway relationships */
tas_pe_pathway AS (
    SELECT DISTINCT pe2p."pe_stable_id",
                    pe2p."pathway_stable_id"
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PE_TO_PATHWAY_V77 pe2p
    WHERE pe2p."evidence_code" = 'TAS'
),
/* 4.  Universe of physical entities with TAS evidence */
tas_pe AS (
    SELECT DISTINCT "pe_stable_id" FROM tas_pe_pathway
),
/* 5.  Physical entities that are NOT sorafenib targets */
non_target_pe AS (
    SELECT "pe_stable_id"
    FROM tas_pe
    WHERE "pe_stable_id" NOT IN (SELECT "pe_stable_id" FROM sorafenib_pe)
),
/* 6.  Total numbers of targets / non-targets in the universe */
totals AS (
    SELECT
        (SELECT COUNT(*) FROM sorafenib_pe)  AS total_targets,
        (SELECT COUNT(*) FROM non_target_pe) AS total_non_targets
),
/* 7.  Candidate pathways: Homo sapiens, lowest level, with TAS evidence */
candidate_pathways AS (
    SELECT DISTINCT
           pw."stable_id" AS pathway_id,
           pw."name"      AS pathway_name
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PATHWAY_V77 pw
    JOIN tas_pe_pathway tpp
      ON pw."stable_id" = tpp."pathway_stable_id"
    WHERE pw."species" ILIKE '%Homo sapiens%'
      AND pw."lowest_level" = TRUE
),
/* 8.  For every candidate pathway, count how many target / non-target PEs fall inside */
pathway_counts AS (
    SELECT
        cp.pathway_id,
        cp.pathway_name,
        COUNT(DISTINCT sp."pe_stable_id") AS targets_in_pathway,       -- a
        COUNT(DISTINCT nt."pe_stable_id") AS non_targets_in_pathway    -- c
    FROM candidate_pathways  cp
    LEFT JOIN tas_pe_pathway tpp ON cp.pathway_id = tpp."pathway_stable_id"
    LEFT JOIN sorafenib_pe   sp  ON tpp."pe_stable_id" = sp."pe_stable_id"
    LEFT JOIN non_target_pe  nt  ON tpp."pe_stable_id" = nt."pe_stable_id"
    GROUP BY cp.pathway_id, cp.pathway_name
),
/* 9.  Chi-square statistic for each pathway */
chi2_calc AS (
    SELECT
        pc.pathway_id,
        pc.pathway_name,
        pc.targets_in_pathway                                           AS a,
        (tot.total_targets     - pc.targets_in_pathway)                 AS b,
        pc.non_targets_in_pathway                                       AS c,
        (tot.total_non_targets - pc.non_targets_in_pathway)             AS d,
        /* χ² = (n(ad − bc)²) / ((a+b)(c+d)(a+c)(b+d)) */
        CASE
            WHEN (pc.targets_in_pathway + (tot.total_targets     - pc.targets_in_pathway)) = 0
              OR (pc.non_targets_in_pathway + (tot.total_non_targets - pc.non_targets_in_pathway)) = 0
              OR (pc.targets_in_pathway + pc.non_targets_in_pathway) = 0
              OR ((tot.total_targets - pc.targets_in_pathway) + (tot.total_non_targets - pc.non_targets_in_pathway)) = 0
            THEN NULL
            ELSE
                (
                  POWER(
                    (pc.targets_in_pathway * (tot.total_non_targets - pc.non_targets_in_pathway)
                     - (tot.total_targets - pc.targets_in_pathway) * pc.non_targets_in_pathway), 2.0)
                  * (tot.total_targets + tot.total_non_targets)
                )
                /
                (
                   (pc.targets_in_pathway + (tot.total_targets - pc.targets_in_pathway))
                 * (pc.non_targets_in_pathway + (tot.total_non_targets - pc.non_targets_in_pathway))
                 * (pc.targets_in_pathway + pc.non_targets_in_pathway)
                 * ((tot.total_targets - pc.targets_in_pathway) + (tot.total_non_targets - pc.non_targets_in_pathway))
                )
        END AS chi2_stat
    FROM pathway_counts pc, totals tot
)
SELECT
    pathway_id,
    pathway_name,
    a AS targets_in_pathway,
    b AS targets_outside_pathway,
    c AS non_targets_in_pathway,
    d AS non_targets_outside_pathway,
    chi2_stat
FROM chi2_calc
ORDER BY chi2_stat DESC NULLS LAST
LIMIT 3;