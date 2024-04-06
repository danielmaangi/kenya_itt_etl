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
all_fp_des <- fp_data |> distinct(de_name, product) |> arrange(de_name) |> as_tibble()
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
    dispensed = sum(value[coc_name == "Dispensed"]),
    clients = sum(value[coc_name == "New clients"]) + sum(value[coc_name == "Re-visits"]),
    expired = sum(value[coc_name == "Expired"]),
    expire_in_6m = sum(value[coc_name == "Quantity expiring in less than 6 months"]),
    losses = sum(value[coc_name == "Losses"]),
    negative_adjust = sum(value[coc_name == "Negative"]),
    positive_adjust = sum(value[coc_name == "Positive"])
  ) |>
  ungroup() |>
  complete(Programme, orgUnit, product, period) |>
  as.data.table()

# Calculate the lagged values within groups
fp_transform[, end_bal_lag1 := shift(end_bal), 
             by = .(Programme, orgUnit, product)]

# Calculate rolling sum for each group
fp_transform[, dispensed_sum_3m := frollsum(dispensed, n = 3), 
             by = .(Programme, orgUnit, product)]

# calculate amc @ site
fp_transform[, amc_3m := frollmean(dispensed, n = 3), 
             by = .(Programme, orgUnit, product)]



fp_transform <- fp_transform |>
  dtplyr::lazy_dt() |>
  group_by(Programme, orgUnit, product, period) |>
  arrange(Programme, orgUnit, product) |>
  ungroup() |>
  mutate(diff = end_bal_lag1 - begin_bal,
         abs_diff = abs(diff),
         abs_diff_percent = ifelse(end_bal_lag1 == 0, NA_real_ , abs_diff / end_bal_lag1),
         abs_diff_percent_10 = dplyr::case_when(abs_diff_percent <= 0.1 ~ 1,
                                     abs_diff_percent > 0.1 ~ 0,
                                     TRUE ~ NA_real_),
         mos_3m = ifelse(end_bal == 0, NA_real_ , end_bal / amc_3m),
         stock_status = case_when(mos_3m == 0 ~ "Stock out",
                                  mos_3m > 0 & mos_3m < 1 ~ "Understock",
                                  mos_3m >= 1 & mos_3m < 4 ~ "Adequate",
                                  mos_3m >= 4 ~ "Overstock",
                                  TRUE ~ NA_character_),
         expected_end_bal = (rowSums(select(., c("begin_bal", "recieved", "positive_adjust")), na.rm = TRUE) -
                               rowSums(select(., c("dispensed", "losses", "negative_adjust")), na.rm = TRUE))
         ) |>
  group_by(Programme, orgUnit, product, period) |>
  ungroup() |>
  mutate(program_id = fp_dataset) |>
  as.data.table() 

dmpa <- fp_transform |> filter(product == "DMPA-SC") |> filter(orgUnit == "A2m3Fgwhf2v")

fwrite(fp_transform, paste0(project_path, "transform/FP/fp_transform_nulls.csv"))



