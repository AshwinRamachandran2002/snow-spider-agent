--  Summary statistics and top-scoring QTL source
WITH filt AS (
  SELECT c.coloc_log2_h4_h3,
         c.right_study
  FROM   `open-targets-genetics.genetics.variant_disease_coloc` AS c
  JOIN   `open-targets-genetics.genetics.studies`               AS s
         ON c.left_study = s.study_id
  WHERE  c.right_gene_id = 'ENSG00000169174'          -- target gene
    AND  c.coloc_h4  > 0.80                          -- strong colocalisation
    AND  c.coloc_h3  < 0.02
    AND  c.right_bio_feature = 'IPSC'                -- requested cell type
    -- variant must match on either side of the pair
    AND ( CONCAT(c.left_chrom ,'_',c.left_pos ,'_',c.left_ref ,'_',c.left_alt)  = '1_55029009_C_T'
       OR CONCAT(c.right_chrom,'_',c.right_pos,'_',c.right_ref,'_',c.right_alt) = '1_55029009_C_T' )
    -- GWAS trait must mention “lesterol levels”
    AND  LOWER(s.trait_reported) LIKE '%lesterol levels%'
)
SELECT
  AVG(coloc_log2_h4_h3)                               AS avg_log2_h4_h3,
  VAR_POP(coloc_log2_h4_h3)                           AS var_log2_h4_h3,
  MAX(coloc_log2_h4_h3) - MIN(coloc_log2_h4_h3)       AS range_log2_h4_h3,
  ( SELECT right_study
      FROM filt
      ORDER BY coloc_log2_h4_h3 DESC
      LIMIT 1 )                                       AS qtl_source_of_max
FROM filt;