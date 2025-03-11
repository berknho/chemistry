library(dplyr)
library(lubridate)
library(baseballr)

# load data
players <- read.csv("data/transactions/all_transactions.csv")
transactions <- read.csv("data/transactions/all_transactions.csv")
player_ids <- read.csv("data/players/player_ids.csv")

#### Get player ids ####

# iterate through all players
for(player in 1:nrow(players)){
  # get names of player
  full_name = unlist(str_split(players$player_name[player], " "))
  first_name = full_name[1]
  last_name = full_name[2]
  
  # print progress
  print(paste0("Getting player id for ", first_name, " ", last_name, "..."))
  
  # if first player, initialize dataframe
  if(player == 1){ 
    player_ids <- playerid_lookup(last_name = last_name, first_name = first_name)
  } 
  # otherwise append data
  else { 
    player_ids <- rbind(player_ids, playerid_lookup(last_name = last_name, first_name = first_name))
  }
  
}

# export player ids if necessary
# write.csv(player_ids, "data/players/player_ids.csv", row.names = FALSE)

#### Clean Up Player IDs ####

# Function to clean team names
clean_team_name <- function(team) {
  ifelse(team == "the Chicago White Sox", "Chicago White Sox", team)
}

# Add full name column for player ids
player_ids <- player_ids %>%
  mutate(full_name = paste(first_name, last_name)) %>%
  relocate(full_name)

# Join player ids with transactions where full name matches
transaction_ids <- transactions %>%
  left_join(player_ids, by = c("player_name" = "full_name"), relationship = "many-to-many") %>%
  # Columns to keep
  select(date, team_traded_from, team_traded_to, 
         player_name, player_pos, birth_year, mlb_played_first, 
         mlbam_id, retrosheet_id, bbref_id, fangraphs_id) %>%
  # If value is blank, replace with NA
  mutate(across(where(is.character), ~ na_if(., ""))) %>%  
  # Keep if mlb id is not NA
  filter(!is.na(mlbam_id)) %>%
  # Drop duplicates
  distinct() %>%
  mutate(date = mdy(date),
         team_traded_from = clean_team_name(team_traded_from),
         team_traded_to = clean_team_name(team_traded_to))

# Get MLB team ids for major league teams in 2024 season
team_ids <- mlb_teams(season = 2024, sport_ids = 1) %>%
  select(team_id, team_full_name) %>%
  # Add row for Cleveland Indians to have same id as Cleveland Guardians
  bind_rows(data.frame(team_id = 114, team_full_name = "Cleveland Indians"))

# Function to check if a player was on a team's active roster
is_player_on_roster <- function(player_row) {
  team_id_tmp <- team_ids$team_id[team_ids$team_full_name == player_row$team_traded_from]
  season_tmp <- year(player_row$date)
  
  print(paste0("season: ", season_tmp))
  print(paste0("player: ", player_row$player_name))
  
  if (length(team_id_tmp) == 0) {
    print("Team ID not found")
    return(tibble())
  }
  
  roster_tmp <- mlb_rosters(team_id = team_id_tmp, season = season_tmp, roster_type = "active")
  
  if (player_row$mlbam_id %in% roster_tmp$person_id) {
    return(as_tibble(player_row))
  } else {
    print("player not in roster")
    return(tibble())
  }
}

# Check if rosters contain player ids for each player
players_cleaned <- transaction_ids %>%
  rowwise() %>%
  do(is_player_on_roster(.)) %>%
  bind_rows() %>%
  distinct()

# write to csv if necessary
# write.csv(players_cleaned, "data/players/players_cleaned.csv", row.names = FALSE)

