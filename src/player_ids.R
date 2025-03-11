library(baseballr)
library(tidyverse)

# load data
players <- read.csv("data/transactions/all_transactions.csv")

#### get player ids ####

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
