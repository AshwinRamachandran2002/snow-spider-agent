/* --------------------------------------------------------------
   Correlate ccRCC proteome log2-ratios with RNA-seq expression
   for “Primary Tumor” and “Solid Tissue Normal” specimens
----------------------------------------------------------------*/

WITH ccRCC_cases AS (          /* 1. clear-cell renal cases */
    SELECT DISTINCT "case_submitter_id"
    FROM   CPTAC_PDC.PDC_METADATA."CASE_METADATA_CURRENT"
    WHERE  "disease_type" ILIKE '%Renal%'
       AND "disease_type" ILIKE '%Clear%Cell%'
),

rna AS (                       /* 2. RNA-seq  log2(FPKM+1)  */
    SELECT
        r."sample_barcode"                         AS sample_id,
        r."gene_name"              AS "gene_symbol",
        LOG(2 , r."fpkm_unstranded" + 1)           AS log2_fpkm,      -- Snowflake: LOG(base , value)
        r."sample_type_name"        AS "sample_type"
    FROM   CPTAC_PDC.CPTAC."RNASEQ_HG38_GDC_CURRENT" r
    WHERE  r."sample_type_name" IN ('Primary Tumor','Solid Tissue Normal')
       AND r."case_barcode" IN (SELECT * FROM ccRCC_cases)
),

aliquot_map AS (               /* 3. map aliquots → sample_id / type */
    SELECT DISTINCT
        a."aliquot_submitter_id",
        a."sample_submitter_id"     AS sample_id,
        a."sample_type"             AS "sample_type"
    FROM   CPTAC_PDC.PDC_METADATA."ALIQUOT_TO_CASE_MAPPING_CURRENT" a
    WHERE  a."sample_type" IN ('Primary Tumor','Solid Tissue Normal')
),

prot AS (                      /* 4. ccRCC proteome values */
    SELECT
        p."aliquot_submitter_id",
        p."gene_symbol",
        p."protein_abundance_log2ratio"
    FROM   CPTAC_PDC.CPTAC."QUANT_PROTEOME_CPTAC_CCRCC_DISCOVERY_STUDY_PDC_CURRENT" p
    WHERE  p."protein_abundance_log2ratio" IS NOT NULL
),

corr_per_gene AS (             /* 5. gene-wise correlations per type */
    SELECT
        r."gene_symbol",
        r."sample_type",
        CORR(r.log2_fpkm , p."protein_abundance_log2ratio") AS corr_value
    FROM   rna            r
    JOIN   aliquot_map    m ON r.sample_id           = m.sample_id
                           AND r."sample_type"       = m."sample_type"
    JOIN   prot           p ON m."aliquot_submitter_id" = p."aliquot_submitter_id"
                           AND r."gene_symbol"          = p."gene_symbol"
    GROUP BY
        r."gene_symbol",
        r."sample_type"
    HAVING ABS( CORR(r.log2_fpkm , p."protein_abundance_log2ratio") ) > 0.5
)

SELECT                       /* 6. average correlation by sample type */
    "sample_type",
    AVG(corr_value) AS avg_correlation
FROM   corr_per_gene
GROUP BY "sample_type"
ORDER BY "sample_type";