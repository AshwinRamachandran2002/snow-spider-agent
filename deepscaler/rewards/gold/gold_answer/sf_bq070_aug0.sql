-- Task: Generate a clean, structured dataset from the "IDC.IDC_V17.DICOM_ALL" table that includes SM (Slide Microscopy) images where "Modality" is 'SM' and the third element of "ImageType" equals 'VOLUME'. Include images from the 'tcga_luad' and 'tcga_lusc' collections, representing TCGA-LUAD and TCGA-LUSC respectively. Exclude images where the calculated "compression" type is 'other', determined by mapping "TransferSyntaxUID" values ('1.2.840.10008.1.2.4.50' to 'jpeg', '1.2.840.10008.1.2.4.91' to 'jpeg2000', others to 'other'). Include only images where the specimen preparation step has "Embedding medium" set to "Tissue freezing medium", extracted from the "SpecimenPreparationSequence" field. Ensure the tissue type is 'normal' or 'tumor', determined by mapping "CodeValue" entries ('17621005' to 'normal', '86049000' to 'tumor') in the "SpecimenDescriptionSequence" field. For each image, include fields such as "digital_slide_id", "case_id", "physical_slide_id", "patient_id", image dimensions ("width", "height"), "collection_id", "crdc_instance_uuid", "gcs_url", "pixel_spacing", "compression", "tissue_type", and add "cancer_subtype" by replacing 'tcga_luad' with 'luad' and 'tcga_lusc' with 'lscc' in "collection_id". Order the final dataset by "crdc_instance_uuid".

WITH
  sm_images AS (
    SELECT
      "SeriesInstanceUID" AS "digital_slide_id", 
      "StudyInstanceUID" AS "case_id",
      "ContainerIdentifier" AS "physical_slide_id",
      "PatientID" AS "patient_id",
      "TotalPixelMatrixColumns" AS "width", 
      "TotalPixelMatrixRows" AS "height",
      "collection_id",
      "crdc_instance_uuid",
      "gcs_url", 
      CAST(
        "SharedFunctionalGroupsSequence"[0]."PixelMeasuresSequence"[0]."PixelSpacing"[0] AS FLOAT
      ) AS "pixel_spacing", 
      CASE "TransferSyntaxUID"
          WHEN '1.2.840.10008.1.2.4.50' THEN 'jpeg'
          WHEN '1.2.840.10008.1.2.4.91' THEN 'jpeg2000'
          ELSE 'other'
      END AS "compression"
    FROM
      IDC.IDC_V17.DICOM_ALL
    WHERE
      "Modality" = 'SM' 
      AND "ImageType"[2] = 'VOLUME'
  ),

  tissue_types AS (
    SELECT DISTINCT *
    FROM (
      SELECT
        "SeriesInstanceUID" AS "digital_slide_id",
        CASE "steps_unnested2".value:"CodeValue"::STRING
            WHEN '17621005' THEN 'normal' -- meaning: 'Normal' (i.e., non-neoplastic)
            WHEN '86049000' THEN 'tumor'  -- meaning: 'Neoplasm, Primary'
            ELSE 'other'                 -- meaning: 'Neoplasm, Metastatic'
        END AS "tissue_type"
      FROM
        IDC.IDC_V17.DICOM_ALL
        CROSS JOIN
          LATERAL FLATTEN(input => "SpecimenDescriptionSequence"[0]."PrimaryAnatomicStructureSequence") AS "steps_unnested1"
        CROSS JOIN
          LATERAL FLATTEN(input => "steps_unnested1".value:"PrimaryAnatomicStructureModifierSequence") AS "steps_unnested2"
    )
  ),

  specimen_preparation_sequence_items AS (
    SELECT DISTINCT *
    FROM (
      SELECT
        "SeriesInstanceUID" AS "digital_slide_id",
        "steps_unnested2".value:"ConceptNameCodeSequence"[0]."CodeMeaning"::STRING AS "item_name",
        "steps_unnested2".value:"ConceptCodeSequence"[0]."CodeMeaning"::STRING AS "item_value"
      FROM
        IDC.IDC_V17.DICOM_ALL
        CROSS JOIN
          LATERAL FLATTEN(input => "SpecimenDescriptionSequence"[0]."SpecimenPreparationSequence") AS "steps_unnested1"
        CROSS JOIN
          LATERAL FLATTEN(input => "steps_unnested1".value:"SpecimenPreparationStepContentItemSequence") AS "steps_unnested2"
    )
  )

SELECT
  a.*,
  b."tissue_type",
  REPLACE(REPLACE(a."collection_id", 'tcga_luad', 'luad'), 'tcga_lusc', 'lscc') AS "cancer_subtype"
FROM 
  sm_images AS a
  JOIN tissue_types AS b 
    ON b."digital_slide_id" = a."digital_slide_id"
  JOIN specimen_preparation_sequence_items AS c 
    ON c."digital_slide_id" = a."digital_slide_id"
WHERE
  (a."collection_id" = 'tcga_luad' OR a."collection_id" = 'tcga_lusc')
  AND a."compression" != 'other'
  AND (b."tissue_type" = 'normal' OR b."tissue_type" = 'tumor')
  AND (c."item_name" = 'Embedding medium' AND c."item_value" = 'Tissue freezing medium')
ORDER BY 
  a."crdc_instance_uuid";