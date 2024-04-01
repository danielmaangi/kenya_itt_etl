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
  mutate(value = as.numeric(value)) |>
  mutate(
    period = as.numeric(period)
    ) |>
  dtplyr::lazy_dt()


# Transformation
# orgunit
all_fp_des <- fp_data |> distinct(de_name) |> arrange(de_name) |> as_tibble()
all_fp_coc <- fp_data |> distinct(coc_name) |> arrange(coc_name) |> as_tibble()
all_fp_attr <- fp_data |> distinct(attr_name) |> arrange(attr_name) |> as_tibble()

# 12 Quantity Received From KEMSA           
# 13 Quantity Received From Kenya Red Cross 


fp_transform <- fp_data |>
  arrange(Programme, orgUnit, product, period) |>
  group_by(Programme, orgUnit, product, period) |>
  arrange(orgUnit, product, period) |>
  summarise(
    end_bal = sum(value[coc_name == "Ending Balance"]),
    begin_bal = sum(value[coc_name == "Beginning Balance"]),
    recieved = sum(value[coc_name %in% c("Quantity Received From KEMSA", "Quantity Received From Kenya Red Cross")]),
    consumed = sum(value[coc_name == "Dispensed"]) # can this be improved?
  ) |>
  ungroup() |>
  complete(Programme, orgUnit, product, period) %>%
  arrange(Programme, orgUnit, product, period) |>
  mutate(end_bal_lag1 = lag(end_bal),
         diff = end_bal_lag1 - begin_bal,
         abs_diff = abs(diff),
         abs_diff_percent = ifelse(end_bal_lag1 == 0, NA_real_ , abs_diff / end_bal_lag1),
         abs_diff_percent_10 = dplyr::case_when(abs_diff_percent <= 0.1 ~ 1,
                                     abs_diff_percent > 0.1 ~ 0,
                                     TRUE ~ NA_real_),
         abs_diff_percent_10_den = case_when(abs_diff_percent_10 %in% c(0,1) ~ 1,
                                         TRUE ~ 0 )
         ) |>
  group_by(Programme, orgUnit, product, period) |>
  ungroup() |>
  as.data.table()

# fp_transform[, rolling_sum := frollsum(consumed, n = 3, align = "right", fill = NA), 
#              by = .(Programme, orgUnit, product, period)]



# Combine results
all_reports <- bind_rows(fp_data_reports, 
                         imm_data_reports, 
                         mal_data_reports, 
                         nut_data_reports)

fwrite(programs, paste0(project_path, "transform/programs.csv"))




