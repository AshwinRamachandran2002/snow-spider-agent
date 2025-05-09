/*-----------------------------------------------------------
   Top three lowest–level Reactome pathways (TAS evidence) 
   with the largest χ² statistics for Homo sapiens targets of
   sorafenib (median ≤ 100 nM, low/high ≤ 100 nM or NULL)
-----------------------------------------------------------*/
WITH
/* 1.  Sorafenib targets that satisfy the assay constraints  */
sorafenib_targets AS (
  SELECT DISTINCT i.target_uniprotID AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`  AS i
  LEFT JOIN `isb-cgc-bq.targetome_versioned.drug_synonyms_v1` AS ds
         ON i.drugID = ds.drugID
  WHERE (LOWER(i.drugName)            LIKE '%sorafenib%'
         OR  LOWER(COALESCE(ds.synonym, '')) LIKE '%sorafenib%')
    AND i.targetSpecies = 'Homo sapiens'
    AND EXISTS (                       -- assay filters
          SELECT 1
          FROM `isb-cgc-bq.targetome_versioned.experiments_v1` AS e
          WHERE e.expID = i.expID
            AND e.exp_assayValueMedian IS NOT NULL
            AND e.exp_assayValueMedian <= 100
            AND (e.exp_assayValueLow  IS NULL OR e.exp_assayValueLow  <= 100)
            AND (e.exp_assayValueHigh IS NULL OR e.exp_assayValueHigh <= 100)
    )
),

/* 2.  Universe = all human proteins (UniProt IDs) present in
        any lowest–level pathway with TAS evidence            */
universe AS (
  SELECT DISTINCT pe.uniprot_id
  FROM  `isb-cgc-bq.reactome_versioned.physical_entity_v77` AS pe
  JOIN  `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`   AS ptp
        ON pe.stable_id = ptp.pe_stable_id
  JOIN  `isb-cgc-bq.reactome_versioned.pathway_v77`         AS p
        ON ptp.pathway_stable_id = p.stable_id
  WHERE pe.uniprot_id IS NOT NULL
    AND ptp.evidence_code = 'TAS'
    AND p.species        = 'Homo sapiens'
    AND p.lowest_level   = TRUE
),

/* 3.  Protein membership for every qualifying pathway       */
pathway_members AS (
  SELECT DISTINCT ptp.pathway_stable_id AS pathway_id,
                  pe.uniprot_id
  FROM  `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`   AS ptp
  JOIN  `isb-cgc-bq.reactome_versioned.pathway_v77`         AS p
        ON ptp.pathway_stable_id = p.stable_id
  JOIN  `isb-cgc-bq.reactome_versioned.physical_entity_v77` AS pe
        ON ptp.pe_stable_id = pe.stable_id
  WHERE ptp.evidence_code = 'TAS'
    AND p.species        = 'Homo sapiens'
    AND p.lowest_level   = TRUE
    AND pe.uniprot_id IS NOT NULL
),

/* 4.  Counts of targets / non‑targets inside each pathway   */
counts AS (
  SELECT
    pm.pathway_id,
    COUNTIF(pm.uniprot_id IN (SELECT uniprot_id FROM sorafenib_targets))
        AS target_in_pathway,
    COUNTIF(pm.uniprot_id NOT IN (SELECT uniprot_id FROM sorafenib_targets))
        AS nontarget_in_pathway
  FROM pathway_members pm
  GROUP BY pm.pathway_id
),

/* 5.  Totals for the universe and the target set            */
totals AS (
  SELECT
    (SELECT COUNT(*) FROM sorafenib_targets) AS total_targets,
    (SELECT COUNT(*) FROM universe)          AS total_universe
),

/* 6.  2×2 table plus χ² for every pathway                   */
chi_square AS (
  SELECT
    c.pathway_id,
    c.target_in_pathway                                       AS a,
    (t.total_targets - c.target_in_pathway)                   AS b,
    c.nontarget_in_pathway                                    AS c,
    (t.total_universe - t.total_targets - c.nontarget_in_pathway) AS d,
    -- χ² = N (ad − bc)² / ((a+b)(c+d)(a+c)(b+d))
    ( t.total_universe * POW((c.target_in_pathway *
                              (t.total_universe - t.total_targets - c.nontarget_in_pathway)
                              - (t.total_targets - c.target_in_pathway) *
                                c.nontarget_in_pathway), 2)
    ) /
    NULLIF( ( (c.target_in_pathway + (t.total_targets - c.target_in_pathway)) *
              (c.nontarget_in_pathway +
               (t.total_universe - t.total_targets - c.nontarget_in_pathway)) *
              (c.target_in_pathway + c.nontarget_in_pathway) *
              ((t.total_targets - c.target_in_pathway) +
               (t.total_universe - t.total_targets - c.nontarget_in_pathway)) ),
            0)                                                 AS chi_sq
  FROM counts c
  CROSS JOIN totals t
)

/* 7.  Return the top three pathways by χ² with the 2×2 counts */
SELECT
  ch.pathway_id,
  p.name                                                        AS pathway_name,
  ch.a  AS target_in_pathway,
  ch.b  AS target_not_in_pathway,
  ch.c  AS non_target_in_pathway,
  ch.d  AS non_target_not_in_pathway,
  ch.chi_sq                                                     AS chi_squared_statistic
FROM chi_square ch
JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` p
  ON ch.pathway_id = p.stable_id
ORDER BY chi_squared_statistic DESC
LIMIT 3;