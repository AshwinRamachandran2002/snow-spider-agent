WITH target_data AS (
  SELECT DISTINCT i.target_uniprotID AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1` i
  JOIN `isb-cgc-bq.targetome_versioned.drug_synonyms_v1` ds ON i.drugID = ds.drugID
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1` e ON i.expID = e.expID
  WHERE LOWER(ds.synonym) = 'sorafenib'
    AND LOWER(i.targetSpecies) = 'homo sapiens'
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow <= 100 OR e.exp_assayValueLow IS NULL)
    AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
    AND i.target_uniprotID IS NOT NULL
),
all_uniprot_ids AS (
  SELECT DISTINCT uniprot_id
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77`
  WHERE uniprot_id IS NOT NULL
),
physical_entities AS (
  SELECT DISTINCT uniprot_id, stable_id AS pe_stable_id
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77`
  WHERE uniprot_id IS NOT NULL
),
pe_to_pathways AS (
  SELECT pe_stable_id, pathway_stable_id AS pathway_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`
  WHERE LOWER(evidence_code) = 'tas'
),
pathways AS (
  SELECT stable_id AS pathway_id, name AS pathway_name
  FROM `isb-cgc-bq.reactome_versioned.pathway_v77`
  WHERE LOWER(species) = 'homo sapiens'
    AND lowest_level = TRUE
),
entity_pathways AS (
  SELECT DISTINCT pe.uniprot_id, pt.pathway_id
  FROM physical_entities pe
  JOIN pe_to_pathways pt ON pe.pe_stable_id = pt.pe_stable_id
),
pathway_counts AS (
  SELECT
    ep.pathway_id,
    COUNT(DISTINCT CASE WHEN td.uniprot_id IS NOT NULL THEN ep.uniprot_id END) AS target_in_pathway,
    COUNT(DISTINCT CASE WHEN td.uniprot_id IS NULL THEN ep.uniprot_id END) AS non_target_in_pathway
  FROM entity_pathways ep
  LEFT JOIN target_data td ON ep.uniprot_id = td.uniprot_id
  GROUP BY ep.pathway_id
),
total_counts AS (
  SELECT
    (SELECT COUNT(DISTINCT uniprot_id) FROM target_data) AS total_targets,
    (SELECT COUNT(DISTINCT uniprot_id) FROM all_uniprot_ids WHERE uniprot_id NOT IN (SELECT uniprot_id FROM target_data)) AS total_non_targets
),
chi_squared_calc AS (
  SELECT
    pc.pathway_id,
    pw.pathway_name,
    pc.target_in_pathway,
    pc.non_target_in_pathway,
    total_counts.total_targets AS total_targets,
    total_counts.total_non_targets AS total_non_targets,
    (total_counts.total_targets - pc.target_in_pathway) AS target_out_pathway,
    (total_counts.total_non_targets - pc.non_target_in_pathway) AS non_target_out_pathway,
    -- N is total_targets + total_non_targets
    (total_counts.total_targets + total_counts.total_non_targets) AS N,
    -- Compute chi-squared statistic
    (
     (
      (pc.target_in_pathway * (total_counts.total_non_targets - pc.non_target_in_pathway) - 
       (total_counts.total_targets - pc.target_in_pathway) * pc.non_target_in_pathway
      ) ^ 2
     ) * (total_counts.total_targets + total_counts.total_non_targets)
     /
     (
       NULLIF((pc.target_in_pathway + (total_counts.total_targets - pc.target_in_pathway)) *
       (pc.non_target_in_pathway + (total_counts.total_non_targets - pc.non_target_in_pathway)) *
       (pc.target_in_pathway + pc.non_target_in_pathway) *
       ((total_counts.total_targets - pc.target_in_pathway) + (total_counts.total_non_targets - pc.non_target_in_pathway)), 0)
     )
    ) AS chi_squared_value
  FROM pathway_counts pc
  CROSS JOIN total_counts
  JOIN pathways pw ON pc.pathway_id = pw.pathway_id
  WHERE pc.target_in_pathway > 0
),
top3_pathways AS (
  SELECT pathway_id, pathway_name
  FROM chi_squared_calc
  WHERE chi_squared_value IS NOT NULL
  ORDER BY chi_squared_value DESC
  LIMIT 3
),
targets_in_top3 AS (
  SELECT DISTINCT td.uniprot_id
  FROM target_data td
  JOIN entity_pathways ep ON td.uniprot_id = ep.uniprot_id
  WHERE ep.pathway_id IN (SELECT pathway_id FROM top3_pathways)
),
targets_outside_top3 AS (
  SELECT td.uniprot_id
  FROM target_data td
  WHERE td.uniprot_id NOT IN (SELECT uniprot_id FROM targets_in_top3)
),
non_targets_in_top3 AS (
  SELECT DISTINCT ep.uniprot_id
  FROM entity_pathways ep
  LEFT JOIN target_data td ON ep.uniprot_id = td.uniprot_id
  WHERE td.uniprot_id IS NULL
    AND ep.pathway_id IN (SELECT pathway_id FROM top3_pathways)
),
non_targets_outside_top3 AS (
  SELECT au.uniprot_id
  FROM all_uniprot_ids au
  WHERE au.uniprot_id NOT IN (SELECT uniprot_id FROM target_data)
    AND au.uniprot_id NOT IN (SELECT uniprot_id FROM non_targets_in_top3)
)
SELECT
  'Within Top 3 Pathways' AS `Group`,
  'Yes' AS IsTarget,
  COUNT(DISTINCT uniprot_id) AS Count
FROM targets_in_top3
UNION ALL
SELECT
  'Outside Top 3 Pathways' AS `Group`,
  'Yes' AS IsTarget,
  COUNT(DISTINCT uniprot_id) AS Count
FROM targets_outside_top3
UNION ALL
SELECT
  'Within Top 3 Pathways' AS `Group`,
  'No' AS IsTarget,
  COUNT(DISTINCT uniprot_id) AS Count
FROM non_targets_in_top3
UNION ALL
SELECT
  'Outside Top 3 Pathways' AS `Group`,
  'No' AS IsTarget,
  COUNT(DISTINCT uniprot_id) AS Count
FROM non_targets_outside_top3;