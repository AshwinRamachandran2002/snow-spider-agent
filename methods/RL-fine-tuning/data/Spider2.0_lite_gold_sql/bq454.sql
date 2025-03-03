WITH SampleInfo AS (
  SELECT
    Sample,
    Super_Population
  FROM
    `genomics-public-data.1000_genomes.sample_info`
),

VariantsWithGenotypes AS (
  SELECT
    v.reference_name,
    v.start,
    v.reference_bases,
    v.alternate_bases[OFFSET(0)] AS alternate_base,
    v.VT AS Variant_Type,
    c.call_set_name,
    c.genotype
  FROM
    `genomics-public-data.1000_genomes.variants` v,
    UNNEST(v.call) AS c
  WHERE
    v.reference_name NOT IN ('X', 'Y', 'MT')
    AND ARRAY_LENGTH(v.alternate_bases) = 1  -- Consider biallelic variants for simplicity
),

VariantSuperPopGenotypes AS (
  SELECT
    v.reference_name,
    v.start,
    v.reference_bases,
    v.alternate_base,
    v.Variant_Type,
    s.Super_Population,
    v.genotype
  FROM
    VariantsWithGenotypes v
  JOIN
    SampleInfo s
  ON
    v.call_set_name = s.Sample
  WHERE
    v.genotype IS NOT NULL
    AND ARRAY_LENGTH(v.genotype) = 2  -- Ensure diploid genotypes
),

AlleleFrequencies AS (
  SELECT
    reference_name,
    start,
    reference_bases,
    alternate_base,
    Variant_Type,
    Super_Population,
    SUM(
      (CASE WHEN genotype[OFFSET(0)] = 1 THEN 1 ELSE 0 END) +
      (CASE WHEN genotype[OFFSET(1)] = 1 THEN 1 ELSE 0 END)
    ) AS alt_allele_count,
    COUNT(*) * 2 AS total_alleles
  FROM
    VariantSuperPopGenotypes
  GROUP BY
    reference_name, start, reference_bases, alternate_base, Variant_Type, Super_Population
),

CommonVariants AS (
  SELECT
    reference_name,
    start,
    reference_bases,
    alternate_base,
    Variant_Type,
    Super_Population,
    SAFE_DIVIDE(alt_allele_count, total_alleles) AS AF
  FROM
    AlleleFrequencies
  WHERE
    total_alleles > 0
    AND SAFE_DIVIDE(alt_allele_count, total_alleles) >= 0.05  -- Common variants with AF ≥ 0.05
),

VariantSuperPopList AS (
  SELECT
    reference_name,
    start,
    reference_bases,
    alternate_base,
    Variant_Type,
    ARRAY_AGG(DISTINCT Super_Population ORDER BY Super_Population) AS Super_Populations
  FROM
    CommonVariants
  GROUP BY
    reference_name, start, reference_bases, alternate_base, Variant_Type
),

VariantCombinationCounts AS (
  SELECT
    Super_Populations,
    Variant_Type,
    COUNT(*) AS Number_of_Common_Autosomal_Variants
  FROM
    VariantSuperPopList
  GROUP BY
    Super_Populations, Variant_Type
),

PopulationSizes AS (
  SELECT
    Super_Population,
    COUNT(DISTINCT Sample) AS Total_Population_Size,
    COUNT(DISTINCT Sample) AS Sample_Count
  FROM
    SampleInfo
  GROUP BY
    Super_Population
),

FinalResults AS (
  SELECT
    ARRAY_TO_STRING(Super_Populations, ',') AS Super_Populations,
    SUM(ps.Total_Population_Size) AS Total_Population_Size,
    SUM(ps.Sample_Count) AS Sample_Count,
    Variant_Type,
    Number_of_Common_Autosomal_Variants
  FROM
    VariantCombinationCounts vc
  JOIN
    PopulationSizes ps
  ON
    ps.Super_Population IN UNNEST(vc.Super_Populations)
  GROUP BY
    Super_Populations, Variant_Type, Number_of_Common_Autosomal_Variants
)

SELECT
  Super_Populations,
  Total_Population_Size,
  Variant_Type,
  Sample_Count,
  Number_of_Common_Autosomal_Variants
FROM
  FinalResults
ORDER BY
  Number_of_Common_Autosomal_Variants DESC;