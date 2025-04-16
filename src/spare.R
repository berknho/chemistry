### relief / bullpen pitcher line

# pre trade

# post trade

### starting pitchers

# pre trade

# post trade

library(dplyr)
library(xtable)

# Filter for relievers and starters based on avg_IP > 4 for starters, <= 4 for relievers
relievers <- pitching_avg %>%
  filter(avg_IP <= 4) %>%  # Relievers typically pitch fewer innings
  group_by(trade_status) %>%
  summarise(across(c(avg_IP, er_avg, wp_avg, k_per9_avg, bb_per9_avg, whip_avg, babip_avg, fip_avg, pitches_avg), mean, na.rm = TRUE))

starters <- pitching_avg %>%
  filter(avg_IP > 4) %>%  # Starters typically pitch more than 4 innings
  group_by(trade_status) %>%
  summarise(across(c(avg_IP, er_avg, wp_avg, k_per9_avg, bb_per9_avg, whip_avg, babip_avg, fip_avg, pitches_avg), mean, na.rm = TRUE))

# Combine relievers and starters into one table
combined_table <- bind_rows(
  mutate(relievers, type = "Relief / Bullpen Pitchers"),
  mutate(starters, type = "Starting Pitchers")
)

# Generate LaTeX table using xtable
latex_table <- xtable(combined_table, type = "latex")

print(latex_table, 
      include.rownames = FALSE,  # Turn off row index
      booktabs = TRUE, 
      floating = TRUE)








days_difference <- function(data, date_column, given_date) {
  data[[date_column]] <- as.Date(data[[date_column]])
  
  given_date <- as.Date(given_date)
  
  data$days_difference <- as.numeric(given_date - data[[date_column]])
  
  return(data)
}

# Apply days_difference function
pitches_all <- days_difference(pitches_all, "game_date", "2023-09-29")  # Adjust the given date as needed

# 2. Create a new column for the number of days a pitcher has been catching with the same catcher
# We will calculate this per pitcher-catcher pairing
pitches_all <- pitches_all %>%
  arrange(player_name, batter, game_date) %>%
  group_by(player_name, batter) %>%
  mutate(days_with_same_catcher = row_number()) %>%
  ungroup()

# 3. Calculate the average performance for each pitcher-catcher pairing
# Example: Let's assume 'woba_value' is a performance metric you want to track
avg_performance <- pitches_all %>%
  group_by(player_name, batter) %>%
  summarize(avg_woba = mean(woba_value, na.rm = TRUE),
            avg_launch_speed = mean(launch_speed, na.rm = TRUE),
            avg_spin_rate = mean(spin_rate_deprecated, na.rm = TRUE),
            .groups = "drop")

# 4. Merge the calculated average performance back to the main dataset
pitches_all <- pitches_all %>%
  left_join(avg_performance, by = c("player_name", "batter"))

# 5. Create the scatter plot of average performance vs. days with same catcher
ggplot(pitches_all, aes(x = days_with_same_catcher, y = avg_woba)) +
  geom_point() +
  geom_smooth(method = "lm", color = "blue") + 
  labs(title = "Pitcher Performance vs. Days with Same Catcher",
       x = "Days with Same Catcher",
       y = "Average wOBA") +
  ggthemes::theme_fivethirtyeight()








# 3. Calculate the average performance for each pitcher-catcher pairing
avg_performance <- pitches_all %>%
  group_by(player_name, batter) %>%
  summarize(avg_launch_speed = mean(launch_speed, na.rm = TRUE),
            avg_spin_rate = mean(spin_rate_deprecated, na.rm = TRUE),
            .groups = "drop")

# 4. Merge the calculated average performance back to the main dataset
pitches_all <- pitches_all %>%
  left_join(avg_performance, by = c("player_name", "batter"))

# 5. Create the scatter plot of average performance vs. days with same catcher
ggplot(pitches_all, aes(x = days_with_same_catcher, y = avg_launch_speed)) +
  geom_point() +
  geom_smooth(method = "lm", color = "blue") + 
  labs(title = "Pitcher Performance vs. Days with Same Catcher",
       x = "Days with Same Catcher",
       y = "Average Launch Speed (mph)") +
  ggthemes::theme_fivethirtyeight()



# Function to calculate days with catcher and average release_spin_rate
calculate_spin_rate_performance <- function(data, pitcher_column, catcher_column, date_column) {
  data[[date_column]] <- as.Date(data[[date_column]])  # Ensure date column is Date type
  data <- data %>%
    arrange(!!sym(pitcher_column), !!sym(catcher_column), !!sym(date_column)) %>%
    group_by(!!sym(pitcher_column), !!sym(catcher_column)) %>%
    mutate(
      days_with_catcher = as.numeric(difftime(!!sym(date_column), min(!!sym(date_column)), units = "days")),
      avg_release_spin_rate = mean(release_spin_rate, na.rm = TRUE)  # Calculate the average release_spin_rate
    )
  return(data)
}


df <- calculate_spin_rate_performance(pitches_all, "player_name", "fielder_2", "game_date")

# Visualize the relationship between days with the same catcher and release_spin_rate
ggplot(df, aes(x = days_with_catcher, y = avg_release_spin_rate)) +
  geom_point() +
  labs(
    title = "Pitcher Release Spin Rate vs. Days with Same Catcher",
    x = "Days with Same Catcher",
    y = "Average Release Spin Rate"
  ) +
  ggthemes::theme_fivethirtyeight()



release_speed_performance <- pitches_all %>%
  group_by(pitcher, fielder_2) %>%
  arrange(pitcher, fielder_2, game_date) %>%
  mutate(days_with_catcher = row_number()) %>%  # Count days with same catcher for each pitcher
  summarise(avg_k9 = mean(release_speed, na.rm = TRUE))  # Calculate avg release speed for each group

# View the first few rows of the summary
head(release_speed_performance)

# Scatter plot of release speed vs. days with same catcher
ggplot(release_speed_performance, aes(x = days_with_catcher, y = avg_release_speed)) +
  geom_point() +
  labs(
    title = "Release Speed vs. Days with Same Catcher",
    x = "Days with Same Catcher",
    y = "Average Release Speed (mph)"
  ) +
  theme_minimal()

df_with_release_speed <- df %>%
  left_join(release_speed_performance, by = c("pitcher", "fielder_2"))

# View the joined dataframe
head(df_with_release_speed)

# Scatter plot of release speed vs. days with same catcher from the joined dataframe
ggplot(df_with_release_speed, aes(x = days_with_catcher, y = avg_release_speed)) +
  geom_point() +
  labs(
    title = "Release Speed vs. Days with Same Catcher",
    x = "Days with Same Catcher",
    y = "Average Release Speed (mph)"
  ) +
  theme_fivethirtyeight()