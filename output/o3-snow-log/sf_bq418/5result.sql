WITH soraf_targets AS (  -- UniProt IDs of human sorafenib targets (median ≤ 100 nM; low / high ≤ 100 nM or NULL)
    SELECT DISTINCT i."target_uniprotID"
    FROM   TARGETOME_REACTOME.TARGETOME_VERSIONED."INTERACTIONS_V1"   i
    JOIN   TARGETOME_REACTOME.TARGETOME_VERSIONED."EXPERIMENTS_V1"    e
           ON e."expID" = i."expID"
    WHERE  i."drugID"        = 157                      -- Sorafenib Tosylate
      AND  i."targetSpecies" = 'Homo sapiens'
      AND  COALESCE(e."exp_assayValueMedian",0) <= 100
      AND (e."exp_assayValueLow"  IS NULL OR e."exp_assayValueLow"  <= 100)
      AND (e."exp_assayValueHigh" IS NULL OR e."exp_assayValueHigh" <= 100)
),
soraf_targets_pe AS (     -- Reactome physical-entity IDs for those targets
    SELECT DISTINCT p."stable_id" AS "pe_stable_id"
    FROM   TARGETOME_REACTOME.REACTOME_VERSIONED."PHYSICAL_ENTITY_V77" p
    JOIN   soraf_targets s
           ON s."target_uniprotID" = p."uniprot_id"
),
all_pe AS (               -- Universe of Reactome physical-entity IDs
    SELECT DISTINCT p."stable_id" AS "pe_stable_id"
    FROM   TARGETOME_REACTOME.REACTOME_VERSIONED."PHYSICAL_ENTITY_V77" p
    WHERE  p."stable_id" IS NOT NULL
),
pathway_pe AS (           -- PE-to-pathway links that have TAS evidence
    SELECT DISTINCT p2p."pathway_stable_id",
                    p2p."pe_stable_id"
    FROM   TARGETOME_REACTOME.REACTOME_VERSIONED."PE_TO_PATHWAY_V77" p2p
    WHERE  p2p."evidence_code" = 'TAS'
),
pathway_counts AS (       -- 2×2 table pieces for each lowest-level human pathway
    SELECT  pw."stable_id" AS "pathway_stable_id",
            COUNT(DISTINCT CASE WHEN st."pe_stable_id" IS NOT NULL
                                THEN st."pe_stable_id" END)          AS targets_in_path,
            COUNT(DISTINCT CASE WHEN st."pe_stable_id" IS NULL
                                THEN ap."pe_stable_id" END)          AS nontargets_in_path
    FROM   TARGETOME_REACTOME.REACTOME_VERSIONED."PATHWAY_V77" pw
    JOIN   pathway_pe  pp  ON pp."pathway_stable_id" = pw."stable_id"
    JOIN   all_pe      ap  ON ap."pe_stable_id"      = pp."pe_stable_id"
    LEFT  JOIN soraf_targets_pe st
           ON st."pe_stable_id" = ap."pe_stable_id"
    WHERE  pw."species"      = 'Homo sapiens'
      AND  pw."lowest_level" = TRUE
    GROUP BY pw."stable_id"
),
totals AS (               -- Add overall totals of targets / non-targets
    SELECT  pc.*,
            (SELECT COUNT(*) FROM soraf_targets_pe)                       AS total_targets,
            (SELECT COUNT(*) FROM all_pe) -
            (SELECT COUNT(*) FROM soraf_targets_pe)                       AS total_nontargets
    FROM    pathway_counts pc
),
chi_sq_calc AS (          -- Compute chi-square statistic for each pathway
    SELECT  t.*,
            ( (t.total_targets + t.total_nontargets) *
              POWER( (t.targets_in_path *
                      (t.total_nontargets - t.nontargets_in_path)) -
                     ((t.total_targets - t.targets_in_path) *
                      t.nontargets_in_path),
                     2) )
            /
            ( t.total_targets *
              t.total_nontargets *
              (t.targets_in_path + t.nontargets_in_path) *
              ((t.total_targets - t.targets_in_path) +
               (t.total_nontargets - t.nontargets_in_path)) )           AS chi_sq
    FROM   totals t
)
SELECT  c."pathway_stable_id",
        pw."name"                               AS "pathway_name",
        c.targets_in_path,
        (c.total_targets     - c.targets_in_path)      AS targets_out_path,
        c.nontargets_in_path,
        (c.total_nontargets - c.nontargets_in_path)    AS nontargets_out_path
FROM    chi_sq_calc           c
JOIN    TARGETOME_REACTOME.REACTOME_VERSIONED."PATHWAY_V77" pw
        ON pw."stable_id" = c."pathway_stable_id"
ORDER BY c.chi_sq DESC NULLS LAST
LIMIT 3;