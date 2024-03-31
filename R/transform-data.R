#-----------------------------------------------------------------------
source(paste0(project_path, "R/packages.R"))

# meta data
dataelements <- fread(paste0(project_path, "metadata/dataelements.csv")) |>
  select(-c(formName)) |>
  rename(de_name = name)

categoryoptions <- fread(paste0(project_path, "metadata/categoryoptions.csv")) |>
  rename(co_name = name)

categoryoptioncombos <- fread(paste0(project_path, "metadata/categoryoptioncombos.csv")) |>
  rename(coc_name = name)

# Read all CSV files into a single data frame using map_df
fp_data <- map_df(list.files(paste0(project_path, "raw/FP/"), 
                             pattern = "\\.csv$", full.names = TRUE),
                  ~fread(.x, colClasses = "character")) %>%
  mutate(Programme = "Family Planning")|>
  select(Programme, dataElement:value) |>
  left_join(dataelements, by = c("dataElement" = "id")) |>
  left_join(categoryoptioncombos, by = c("categoryOptionCombo" = "id") ) |>
  left_join(categoryoptioncombos, by = c("attributeOptionCombo" = "id")) |>
  rename(coc_name = coc_name.x,
         attr_name = coc_name.y) |>
  mutate(
    product = str_remove_all(de_name,"MOH 747A_service_2 |MOH 747A_service_|MOH 747A_")) |>
  filter(valueType %in% c("NUMBER", "INTEGER", "INTEGER_ZERO_OR_POSITIVE")) |>
  mutate(value = as.numeric(value),
         period_numeric = as.numeric(gsub("(\\d{4})(\\d{2})", "\\1.\\2", period)))


# Transformation
# orgunit
all_fp_des <- fp_data |> distinct(de_name) |> arrange(de_name)
all_fp_coc <- fp_data |> distinct(coc_name) |> arrange(coc_name)
all_fp_attr <- fp_data |> distinct(attr_name) |> arrange(attr_name)

fp_transform <- fp_data |>
  arrange(Programme, orgUnit, product, period) |>
  group_by(Programme, orgUnit, product, period) |>
  arrange(orgUnit, product, period) |>
  summarise(
    end_bal = sum(value[coc_name == "Ending Balance"]),
    begin_bal = sum(value[coc_name == "Beginning Balance"]),
    consumption = sum(value[coc_name == "Dispensed"]) # can this be improved?
    
  ) |>
  mutate(end_bal_lag1 = lag(end_bal))
  





imm_data_reports <- map_df(list.files(paste0(project_path, "raw/Reports/Immunization/"), 
                                      pattern = "\\.csv$", full.names = TRUE),
                           fread) |>
  mutate(Programme = "Immunization")

mal_data_reports <- map_df(list.files(paste0(project_path, "raw/Reports/Malaria/"), 
                                      pattern = "\\.csv$", full.names = TRUE),
                           fread) |>
  mutate(Programme = "Malaria")

nut_data_reports <- map_df(list.files(paste0(project_path, "raw/Reports/Nutrition/"), 
                                      pattern = "\\.csv$", full.names = TRUE),
                           fread) |>
  mutate(Programme = "Nutrition")

all_reports <- bind_rows(fp_data_reports, 
                         imm_data_reports, 
                         mal_data_reports, 
                         nut_data_reports) |>
  separate_wider_delim(Data, ".", names = c("Dataset ID", "Indicator")) |>
  pivot_wider(names_from = Indicator,
              values_from = Value) |>
  filter(EXPECTED_REPORTS > 0)

fwrite(all_reports, paste0(project_path, "transform/reports.csv"))

programs <- all_reports |>
  distinct(`Dataset ID`, Programme)

fwrite(programs, paste0(project_path, "transform/programs.csv"))




