/* ------------------------------------------------------------
   Correlate protein abundance (log2-ratio) with log2(FPKM+1)
   RNA expression for Clear Cell Renal Cell Carcinoma (CCRCC).

   – Kidney RNA-seq (Primary Tumor / Solid Tissue Normal)
   – CCRCC discovery proteome
   – Aliquot-to-sample mapping table supplies the link
     between proteome aliquot IDs and RNA sample barcodes.
   ------------------------------------------------------------ */
WITH rna AS (               -- 1)  RNA-seq: average replicates
  SELECT
    sample_barcode,                        -- e.g. C3N-01651-01
    sample_type_name,                      -- Primary Tumor / Solid Tissue Normal
    gene_name       AS gene_symbol,
    AVG(fpkm_unstranded) AS mean_fpkm
  FROM `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`
  WHERE primary_site = 'Kidney'
    AND sample_type_name IN ('Primary Tumor','Solid Tissue Normal')
  GROUP BY sample_barcode, sample_type_name, gene_symbol
),
rna_log AS (             -- 2)  log2(FPKM+1)
  SELECT
    sample_barcode,
    sample_type_name,
    gene_symbol,
    LOG(mean_fpkm + 1, 2) AS log2_fpkm
  FROM rna
),

aliquot_map AS (         -- 3)  map proteome aliquot → RNA sample_barcode
  SELECT DISTINCT
    aliquot_submitter_id,
    sample_submitter_id AS sample_barcode     -- matches RNA sample_barcode
  FROM `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current`
  WHERE sample_submitter_id IS NOT NULL
),

prot_raw AS (            -- 4)  CCRCC proteome linked to sample_barcode
  SELECT
    m.sample_barcode,
    p.gene_symbol,
    p.protein_abundance_log2ratio
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` p
  JOIN aliquot_map m
    ON p.aliquot_submitter_id = m.aliquot_submitter_id
  WHERE p.protein_abundance_log2ratio IS NOT NULL
),

prot AS (                -- 5)  average any technical replicates
  SELECT
    sample_barcode,
    gene_symbol,
    AVG(protein_abundance_log2ratio) AS protein_abundance_log2ratio
  FROM prot_raw
  GROUP BY sample_barcode, gene_symbol
),

joined AS (              -- 6)  merge RNA + protein on sample & gene
  SELECT
    r.sample_type_name,
    r.gene_symbol,
    r.sample_barcode,
    r.log2_fpkm,
    p.protein_abundance_log2ratio
  FROM rna_log r
  JOIN prot   p
    ON r.sample_barcode = p.sample_barcode
   AND r.gene_symbol    = p.gene_symbol
),

gene_corr AS (           -- 7)  Pearson r for each (gene, sample_type)
  SELECT
    sample_type_name,
    gene_symbol,
    CORR(log2_fpkm, protein_abundance_log2ratio) AS corr
  FROM joined
  GROUP BY sample_type_name, gene_symbol
  HAVING ABS(corr) > 0.5                     -- retain strong correlations
)

-- 8)  Mean correlation per sample type
SELECT
  sample_type_name,
  AVG(corr) AS avg_correlation
FROM gene_corr
GROUP BY sample_type_name
ORDER BY sample_type_name;