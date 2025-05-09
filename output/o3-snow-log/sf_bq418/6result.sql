/* ---------------------------------------------------------------
   Top 3 lowest-level Homo sapiens Reactome pathways (TAS evidence)
   with the highest χ² statistic for Sorafenib targets (IC50 ≤100)
-----------------------------------------------------------------*/
WITH
/* 1) Sorafenib targets that pass the assay filters (Homo sapiens) */
sorafenib_targets AS (
    SELECT DISTINCT
           p."stable_id"          AS pe_stable_id
    FROM TARGETOME_REACTOME.TARGETOME_VERSIONED.INTERACTIONS_V1  t
    JOIN TARGETOME_REACTOME.TARGETOME_VERSIONED.EXPERIMENTS_V1   e
         ON t."expID" = e."expID"
    JOIN TARGETOME_REACTOME.REACTOME_VERSIONED.PHYSICAL_ENTITY_V77 p
         ON p."uniprot_id" = t."target_uniprotID"
    WHERE t."drugName" ILIKE '%sorafenib%'
      AND t."targetSpecies" = 'Homo sapiens'
      AND (e."exp_assayValueMedian" <= 100 OR e."exp_assayValueMedian" IS NULL)
      AND (e."exp_assayValueLow"   <= 100 OR e."exp_assayValueLow"   IS NULL)
      AND (e."exp_assayValueHigh"  <= 100 OR e."exp_assayValueHigh"  IS NULL)
),
target_cnt AS (SELECT COUNT(*) AS n_target FROM sorafenib_targets),

/* 2) All PE–pathway pairs supported by TAS in lowest-level H. sapiens pathways */
tas_pathway_pe AS (
    SELECT DISTINCT
           rel."pathway_stable_id"   AS pathway_id,
           rel."pe_stable_id"        AS pe_stable_id
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PE_TO_PATHWAY_V77  rel
    JOIN TARGETOME_REACTOME.REACTOME_VERSIONED.PATHWAY_V77        pw
         ON rel."pathway_stable_id" = pw."stable_id"
    WHERE rel."evidence_code" = 'TAS'
      AND pw."species"       = 'Homo sapiens'
      AND pw."lowest_level"  = TRUE
),
universe_pe      AS (SELECT DISTINCT pe_stable_id FROM tas_pathway_pe),
universe_cnt     AS (SELECT COUNT(*) AS n_universe FROM universe_pe),

/* 3) For every pathway: count Sorafenib targets & non-targets inside */
pathway_counts AS (
    SELECT
        tp.pathway_id,
        COUNT(DISTINCT CASE WHEN st.pe_stable_id IS NOT NULL THEN tp.pe_stable_id END) AS targets_in,
        COUNT(DISTINCT CASE WHEN st.pe_stable_id IS     NULL THEN tp.pe_stable_id END) AS non_targets_in
    FROM tas_pathway_pe tp
    LEFT JOIN sorafenib_targets st
           ON tp.pe_stable_id = st.pe_stable_id
    GROUP BY tp.pathway_id
),

/* 4) Add outside-pathway counts and χ² statistic (2×2)               */
chi2 AS (
    SELECT
        pc.pathway_id,
        pc.targets_in                                                       AS targets_in_pathway,
        tc.n_target  - pc.targets_in                                        AS targets_outside_pathway,
        pc.non_targets_in                                                   AS non_targets_in_pathway,
        (uc.n_universe - tc.n_target) - pc.non_targets_in                   AS non_targets_outside_pathway,

        /* χ² = N * (ad − bc)² / (r1*r2*c1*c2) */
        CASE
          WHEN  tc.n_target = 0
             OR uc.n_universe - tc.n_target = 0
             OR pc.targets_in + pc.non_targets_in = 0
             OR uc.n_universe - pc.targets_in - pc.non_targets_in = 0
          THEN NULL
          ELSE
              ( uc.n_universe
                * POWER( pc.targets_in * ((uc.n_universe - tc.n_target) - pc.non_targets_in)
                        - (tc.n_target - pc.targets_in) * pc.non_targets_in
                       , 2 )
              ) ::DOUBLE
              /
              ( tc.n_target
                * (uc.n_universe - tc.n_target)
                * (pc.targets_in + pc.non_targets_in)
                * (uc.n_universe - pc.targets_in - pc.non_targets_in)
              )
        END                                                                 AS chi_squared
    FROM pathway_counts pc
    CROSS JOIN target_cnt  tc
    CROSS JOIN universe_cnt uc
)

/* 5) Return the three pathways with the highest χ² values            */
SELECT
    c.pathway_id                                 AS "pathway_stable_id",
    pw."name"                                    AS "pathway_name",
    c.targets_in_pathway                         AS "targets_in_pathway",
    c.targets_outside_pathway                    AS "targets_outside_pathway",
    c.non_targets_in_pathway                     AS "non_targets_in_pathway",
    c.non_targets_outside_pathway                AS "non_targets_outside_pathway",
    ROUND(c.chi_squared,4)                       AS "chi_squared"
FROM chi2          c
JOIN TARGETOME_REACTOME.REACTOME_VERSIONED.PATHWAY_V77 pw
     ON c.pathway_id = pw."stable_id"
WHERE c.chi_squared IS NOT NULL
ORDER BY c.chi_squared DESC NULLS LAST
LIMIT 3;