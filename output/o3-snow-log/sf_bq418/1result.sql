WITH
/* 1) Potent (≤ 100 nM) Homo-sapiens sorafenib targets */
potent_targets AS (
    SELECT DISTINCT i."target_uniprotID"
    FROM TARGETOME_REACTOME.TARGETOME_VERSIONED.INTERACTIONS_V1  i
    JOIN TARGETOME_REACTOME.TARGETOME_VERSIONED.EXPERIMENTS_V1   e
          ON i."expID" = e."expID"
    WHERE i."drugID" = 157                      -- Sorafenib
      AND COALESCE(e."exp_assayValueMedian",0) <= 100
      AND (e."exp_assayValueLow"  IS NULL OR e."exp_assayValueLow"  <= 100)
      AND (e."exp_assayValueHigh" IS NULL OR e."exp_assayValueHigh" <= 100)
      AND i."targetSpecies" = 'Homo sapiens'
),
/* 2) Reactome physical entities (PEs) corresponding to those targets */
sorafenib_pe AS (
    SELECT DISTINCT p."stable_id" AS pe_id
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PHYSICAL_ENTITY_V77 p
    JOIN potent_targets t
      ON p."uniprot_id" = t."target_uniprotID"
),
/* 3) Universe of PEs with TAS evidence in lowest-level Homo-sapiens pathways */
universe_pe AS (
    SELECT DISTINCT pp."pe_stable_id" AS pe_id
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PE_TO_PATHWAY_V77 pp
    JOIN TARGETOME_REACTOME.REACTOME_VERSIONED.PATHWAY_V77 pw
      ON pw."stable_id" = pp."pathway_stable_id"
    WHERE pp."evidence_code" = 'TAS'
      AND pw."lowest_level"  = TRUE
      AND pw."species"       = 'Homo sapiens'
),
/* 4) Mark each PE as sorafenib target (1) or not (0) */
universe AS (
    SELECT
        u.pe_id,
        CASE WHEN s.pe_id IS NOT NULL THEN 1 ELSE 0 END AS is_target
    FROM universe_pe u
    LEFT JOIN sorafenib_pe s
      ON u.pe_id = s.pe_id
),
/* 5) Overall totals required for “outside-pathway” cells */
totals AS (
    SELECT
        COUNT(*)           AS N,
        SUM(is_target)     AS total_targets,
        SUM(1-is_target)   AS total_nontargets
    FROM universe
),
/* 6) Inside-pathway counts of targets / non-targets for every pathway */
pathway_in_counts AS (
    SELECT
        pw."stable_id"                  AS pathway_id,
        SUM(u.is_target)                AS targets_in,
        SUM(1-u.is_target)              AS nontargets_in
    FROM TARGETOME_REACTOME.REACTOME_VERSIONED.PE_TO_PATHWAY_V77 pp
    JOIN TARGETOME_REACTOME.REACTOME_VERSIONED.PATHWAY_V77 pw
      ON pw."stable_id" = pp."pathway_stable_id"
    JOIN universe u
      ON u.pe_id = pp."pe_stable_id"
    WHERE pw."lowest_level" = TRUE
      AND pw."species"      = 'Homo sapiens'
      AND pp."evidence_code"= 'TAS'
    GROUP BY pw."stable_id"
),
/* 7) Build 2×2 table for each pathway and compute chi-square statistic */
chi2_table AS (
    SELECT
        pc.pathway_id,
        pc.targets_in,
        pc.nontargets_in,
        (tot.total_targets    - pc.targets_in)      AS targets_out,
        (tot.total_nontargets - pc.nontargets_in)   AS nontargets_out,
        /* Pearson chi-square (1 df) */
        CASE
            WHEN (pc.targets_in + pc.nontargets_in) = 0
              OR (tot.total_targets - pc.targets_in + tot.total_nontargets - pc.nontargets_in) = 0
              OR (pc.targets_in + tot.total_targets - pc.targets_in) = 0
              OR (pc.nontargets_in + tot.total_nontargets - pc.nontargets_in) = 0
            THEN NULL
            ELSE
              tot.N * POWER( pc.targets_in * (tot.total_nontargets - pc.nontargets_in)
                           - pc.nontargets_in * (tot.total_targets - pc.targets_in), 2 )
              / ( (pc.targets_in + pc.nontargets_in)
                  * (tot.total_targets - pc.targets_in + tot.total_nontargets - pc.nontargets_in)
                  * (pc.targets_in + tot.total_targets - pc.targets_in)
                  * (pc.nontargets_in + tot.total_nontargets - pc.nontargets_in) )
        END AS chi2
    FROM pathway_in_counts pc
    CROSS JOIN totals tot
)
/* 8) Return the three pathways with the largest chi-square statistics */
SELECT
    pathway_id,
    targets_in,
    nontargets_in,
    targets_out,
    nontargets_out
FROM chi2_table
ORDER BY chi2 DESC NULLS LAST
LIMIT 3;