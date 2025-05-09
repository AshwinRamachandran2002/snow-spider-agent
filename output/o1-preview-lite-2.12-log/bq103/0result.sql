WITH
  Number_of_variants AS (
    SELECT
      COUNT(DISTINCT CONCAT(CAST(start_position AS STRING), reference_bases, alt.alt)) AS num_variants
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`,
    UNNEST(alternate_bases) AS alt
    WHERE start_position BETWEEN 55039447 AND 55064852
  ),
  Total_Allele_Count AS (
    SELECT
      SUM(alt.AC) AS total_AC
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`,
    UNNEST(alternate_bases) AS alt
    WHERE start_position BETWEEN 55039447 AND 55064852
  ),
  Total_Number_of_Alleles AS (
    SELECT
      SUM(AN) AS total_AN
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
    WHERE start_position BETWEEN 55039447 AND 55064852
  ),
  Mutation_Density AS (
    SELECT
      ROUND(num_variants / CAST((55064852 - 55039447) AS FLOAT64), 4) AS density
    FROM Number_of_variants
  ),
  Distinct_Gene_Symbols AS (
    SELECT STRING_AGG(DISTINCT vep_annotation.Gene) AS Gene_Symbols
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`,
    UNNEST(alternate_bases) AS alt,
    UNNEST(alt.vep) AS vep_annotation
    WHERE start_position BETWEEN 55039447 AND 55064852
      AND vep_annotation.Gene IS NOT NULL
      AND vep_annotation.Gene != ''
  )
SELECT
  n.num_variants AS Number_of_variants,
  t.total_AC AS Total_Allele_Count,
  a.total_AN AS Total_Number_of_Alleles,
  m.density AS Mutation_Density,
  s.Gene_Symbols AS Distinct_Gene_Symbols
FROM Number_of_variants n
JOIN Total_Allele_Count t ON TRUE
JOIN Total_Number_of_Alleles a ON TRUE
JOIN Mutation_Density m ON TRUE
JOIN Distinct_Gene_Symbols s ON TRUE