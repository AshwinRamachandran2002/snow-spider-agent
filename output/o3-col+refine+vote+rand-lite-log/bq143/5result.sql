/*  Correlate gene-level protein abundance with log2-transformed RNA-Seq
    for CPTAC clear-cell RCC (“Primary Tumor” vs “Solid Tissue Normal”).

    Steps
    -----
    1)  Use the PDC aliquot-to-case mapping table to convert proteome
        aliquot IDs to the GDC/CPTAC sample submitter IDs (barcodes).
    2)  Collect Kidney RNA-Seq values, compute log2(FPKM + 1), and – if
        multiple aliquots exist – average to one value per (sample, gene).
    3)  Collect CCRCC proteome log2 ratios, map them to the same sample
        IDs, and (again) average any replicates.
    4)  Join RNA and proteome on (sample_id, gene), producing paired values.
    5)  For each (sample_type, gene) compute Pearson r; retain only |r|>0.5.
    6)  Report the mean of the retained correlations for each sample type.   */

WITH gdc_pdc_map AS (          -- 1)  Aliquot → sample barcode bridge
  SELECT DISTINCT
    aliquot_submitter_id,
    sample_submitter_id AS sample_barcode            -- matches GDC/CPTAC sample ID
  FROM
    `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current`
  WHERE
    aliquot_submitter_id IS NOT NULL
    AND sample_submitter_id IS NOT NULL
),

kidney_rna AS (                -- 2)  Kidney RNA-Seq, averaged per sample+gene
  SELECT
    sample_barcode,
    LOWER(sample_type_name)                    AS sample_type,      -- primary tumor / solid tissue normal
    gene_name                                  AS gene_symbol,
    AVG( LOG(fpkm_unstranded + 1) / LOG(2) )   AS log2_fpkm         -- average across any aliquots
  FROM
    `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`
  WHERE
        LOWER(primary_site)      = 'kidney'
    AND LOWER(sample_type_name) IN ('primary tumor','solid tissue normal')
  GROUP BY sample_barcode, sample_type, gene_symbol
),

ccrcc_proteome AS (            -- 3)  Proteome values mapped & averaged
  SELECT
    m.sample_barcode,
    p.gene_symbol,
    AVG(p.protein_abundance_log2ratio) AS prot_log2ratio
  FROM
    `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` p
  JOIN
    gdc_pdc_map m
      ON m.aliquot_submitter_id = p.aliquot_submitter_id
  WHERE
    p.protein_abundance_log2ratio IS NOT NULL
  GROUP BY m.sample_barcode, p.gene_symbol
),

joined_pairs AS (              -- 4)  Matched RNA / Proteome pairs
  SELECT
    r.sample_type,
    r.gene_symbol,
    r.sample_barcode,
    p.prot_log2ratio,
    r.log2_fpkm
  FROM
    kidney_rna     r
  JOIN
    ccrcc_proteome p
    ON  p.sample_barcode = r.sample_barcode
    AND p.gene_symbol    = r.gene_symbol
  WHERE
        p.prot_log2ratio IS NOT NULL
    AND r.log2_fpkm      IS NOT NULL
),

corr_per_gene AS (             -- 5)  Pearson r by gene & sample type
  SELECT
    sample_type,
    gene_symbol,
    CORR(prot_log2ratio, log2_fpkm) AS gene_corr
  FROM joined_pairs
  GROUP BY sample_type, gene_symbol
  HAVING ABS(gene_corr) > 0.5                -- keep strong correlations
)

-- 6)  Mean correlation for each sample class
SELECT
  INITCAP(sample_type)  AS sample_type_name,
  AVG(gene_corr)        AS avg_correlation
FROM corr_per_gene
GROUP BY sample_type
ORDER BY sample_type_name;