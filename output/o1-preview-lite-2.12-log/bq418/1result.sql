WITH sorafenib_drugIDs AS (
    SELECT DISTINCT drugID
    FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
    WHERE LOWER(synonym) = 'sorafenib'
),
sorafenib_targets AS (
    SELECT DISTINCT i.target_uniprotID AS uniprot_id
    FROM `isb-cgc-bq.targetome_versioned.interactions_v1` i
    JOIN sorafenib_drugIDs sd ON i.drugID = sd.drugID
    JOIN `isb-cgc-bq.targetome_versioned.experiments_v1` e ON i.expID = e.expID
    WHERE LOWER(i.targetSpecies) = 'homo sapiens'
      AND e.exp_assayValueMedian <= 100
      AND (e.exp_assayValueLow <= 100 OR e.exp_assayValueLow IS NULL)
      AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
      AND i.target_uniprotID IS NOT NULL
),
all_targets AS (
    SELECT DISTINCT uniprot_id
    FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77`
    WHERE uniprot_id IS NOT NULL
),
pathway_targets AS (
    SELECT DISTINCT pep.pathway_stable_id AS pathway_id, pe.uniprot_id
    FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` pep
    JOIN `isb-cgc-bq.reactome_versioned.physical_entity_v77` pe ON pep.pe_stable_id = pe.stable_id
    WHERE pep.evidence_code = 'TAS'
      AND pe.uniprot_id IS NOT NULL
),
pathway_info AS (
    SELECT stable_id AS pathway_id, name AS pathway_name
    FROM `isb-cgc-bq.reactome_versioned.pathway_v77`
    WHERE lowest_level = TRUE
),
pathway_stats AS (
    SELECT
        pi.pathway_id,
        pi.pathway_name,
        COUNT(DISTINCT CASE WHEN st.uniprot_id IS NOT NULL THEN pt.uniprot_id END) AS targets_in_pathway,
        COUNT(DISTINCT CASE WHEN st.uniprot_id IS NULL THEN pt.uniprot_id END) AS non_targets_in_pathway
    FROM pathway_info pi
    JOIN pathway_targets pt ON pi.pathway_id = pt.pathway_id
    LEFT JOIN sorafenib_targets st ON pt.uniprot_id = st.uniprot_id
    GROUP BY pi.pathway_id, pi.pathway_name
),
chi_square_data AS (
    SELECT
        pathway_id,
        pathway_name,
        targets_in_pathway,
        (SELECT COUNT(DISTINCT uniprot_id) FROM sorafenib_targets) - targets_in_pathway AS targets_not_in_pathway,
        non_targets_in_pathway,
        (SELECT COUNT(DISTINCT uniprot_id) FROM all_targets) - (SELECT COUNT(DISTINCT uniprot_id) FROM sorafenib_targets) - non_targets_in_pathway AS non_targets_not_in_pathway
    FROM pathway_stats
    WHERE targets_in_pathway > 0
),
final_data AS (
    SELECT
        pathway_id AS Pathway_ID,
        pathway_name AS Pathway_Name,
        targets_in_pathway AS Targets_in_Pathway,
        targets_not_in_pathway AS Targets_not_in_Pathway,
        non_targets_in_pathway AS Non_targets_in_Pathway,
        non_targets_not_in_pathway AS Non_targets_not_in_Pathway,
        CASE WHEN (Targets_in_Pathway + Targets_not_in_Pathway) * 
                   (Non_targets_in_Pathway + Non_targets_not_in_Pathway) * 
                   (Targets_in_Pathway + Non_targets_in_Pathway) * 
                   (Targets_not_in_Pathway + Non_targets_in_Pathway) > 0 THEN
            POWER((Targets_in_Pathway * Non_targets_not_in_Pathway - Non_targets_in_Pathway * Targets_not_in_Pathway), 2) *
            (Targets_in_Pathway + Targets_not_in_Pathway + Non_targets_in_Pathway + Non_targets_not_in_Pathway) /
            ((Targets_in_Pathway + Targets_not_in_Pathway) * (Non_targets_in_Pathway + Non_targets_not_in_Pathway) * (Targets_in_Pathway + Non_targets_in_Pathway) * (Targets_not_in_Pathway + Non_targets_in_Pathway))
        ELSE 0 END AS Chi_squared_statistic
    FROM chi_square_data
)
SELECT
    Pathway_ID,
    Pathway_Name,
    Targets_in_Pathway,
    Targets_not_in_Pathway,
    Non_targets_in_Pathway,
    Non_targets_not_in_Pathway,
    ROUND(Chi_squared_statistic, 4) AS Chi_squared_statistic
FROM final_data
ORDER BY Chi_squared_statistic DESC
LIMIT 3;